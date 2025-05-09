/* --------------------------------------------------------------
   Build pairs of small (10-15 heavy atoms) compounds measured in
   the same assay & standard_type (bucket contains <5 such rows).
   Both activities must have
        • pChEMBL  > 10
        • non-NULL STANDARD_VALUE
        • potential_duplicate < 2

   Output for every ordered pair (activity_id_1 < activity_id_2):
        max_heavy_atoms
        highest_doc_id
        latest_publication_date   (synthetic, via ranking rule)
        standard_change           (increase / decrease / no-change)
        pair_uuid                 = MD5(JSON array [act_id_1,act_id_2])
        uuid_1 / uuid_2           = MD5(JSON object {activity_id,smiles})
-----------------------------------------------------------------*/
WITH docs_enriched AS (   -- add percent-rank inside (journal,year)
    SELECT
        "doc_id",
        COALESCE(TRY_TO_NUMBER("year"),1970)                  AS year_val,
        COALESCE("journal",'UNKNOWN')                         AS journal_val,
        TRY_TO_NUMBER("first_page")                           AS first_page_num,
        PERCENT_RANK() OVER (
               PARTITION BY COALESCE("journal",'UNKNOWN'),
                            COALESCE(TRY_TO_NUMBER("year"),1970)
               ORDER BY TRY_TO_NUMBER("first_page")
        )                                                    AS pct_rank
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."DOCS"
),
docs_dates AS (           -- convert rank → month / day
    SELECT
        "doc_id",
        year_val                                              AS pub_year,
        FLOOR(pct_rank*11) + 1                                AS pub_month,
        MOD(FLOOR(pct_rank*308),28) + 1                       AS pub_day,
        TO_DATE(
            year_val || '-' ||
            LPAD( (FLOOR(pct_rank*11)+1)::STRING ,2,'0') || '-' ||
            LPAD( (MOD(FLOOR(pct_rank*308),28)+1)::STRING ,2,'0')
        )                                                    AS publication_date
    FROM docs_enriched
),
/* ----------------------------------------------------------------- */
eligible_acts AS (        -- activities that pass all filters
    SELECT
        a."activity_id",
        a."assay_id",
        a."standard_type",
        a."molregno",
        TRY_TO_NUMBER(cp."heavy_atoms")           AS heavy_atoms,
        TRY_TO_NUMBER(a."pchembl_value")          AS pchembl_val,
        TRY_CAST(a."standard_value" AS FLOAT)     AS std_val,
        a."standard_relation"                     AS std_rel,
        TRY_TO_NUMBER(a."potential_duplicate")    AS dup_flag,
        a."doc_id"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."ACTIVITIES_27"         a
    JOIN "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES"   cp
           ON a."molregno" = cp."molregno"
    WHERE TRY_TO_NUMBER(cp."heavy_atoms") BETWEEN 10 AND 15
      AND TRY_TO_NUMBER(a."pchembl_value")  > 10
      AND TRY_CAST(a."standard_value" AS FLOAT) IS NOT NULL
      AND TRY_TO_NUMBER(a."potential_duplicate") < 2
),
/* keep only assay/standard_type buckets with <5 eligible rows */
assays_under5 AS (
    SELECT "assay_id","standard_type"
    FROM   eligible_acts
    GROUP  BY "assay_id","standard_type"
    HAVING COUNT(DISTINCT "activity_id") < 5
),
acts_filt AS (
    SELECT ea.*
    FROM   eligible_acts ea
    JOIN   assays_under5 au
      ON   ea."assay_id"      = au."assay_id"
     AND   ea."standard_type" = au."standard_type"
),
/* ----------------------------------------------------------------- */
pairs AS (                 -- ordered pairs inside same assay bucket
    SELECT
        a1."activity_id"                     AS act_id_1,
        a2."activity_id"                     AS act_id_2,
        a1."assay_id",
        a1."standard_type",
        a1.std_val                           AS val_1,
        a1.std_rel                           AS rel_1,
        a2.std_val                           AS val_2,
        a2.std_rel                           AS rel_2,
        a1.heavy_atoms                       AS ha_1,
        a2.heavy_atoms                       AS ha_2,
        a1."doc_id"                          AS doc_id_1,
        a2."doc_id"                          AS doc_id_2,
        a1."molregno"                        AS mol_1,
        a2."molregno"                        AS mol_2
    FROM acts_filt a1
    JOIN acts_filt a2
      ON a1."assay_id"      = a2."assay_id"
     AND a1."standard_type" = a2."standard_type"
     AND a1."activity_id"   < a2."activity_id"
),
/* ----------------------------------------------------------------- */
pairs_smiles AS (          -- attach canonical SMILES
    SELECT
        p.*,
        cs1."canonical_smiles"               AS smiles_1,
        cs2."canonical_smiles"               AS smiles_2
    FROM  pairs p
    JOIN  "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES" cs1
          ON p.mol_1 = cs1."molregno"
    JOIN  "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES" cs2
          ON p.mol_2 = cs2."molregno"
),
/* ----------------------------------------------------------------- */
pairs_final AS (
    SELECT
        act_id_1,
        act_id_2,
        GREATEST(ha_1,ha_2)                                 AS max_heavy_atoms,
        GREATEST( TRY_TO_NUMBER(doc_id_1),
                  TRY_TO_NUMBER(doc_id_2) )                 AS highest_doc_id,
        /* classify value change */
        CASE
            WHEN rel_1='=' AND rel_2='=' AND val_1 = val_2                  THEN 'no-change'
            WHEN rel_1='=' AND rel_2='=' AND val_1 > val_2                  THEN 'decrease'
            WHEN rel_1='=' AND rel_2='=' AND val_1 < val_2                  THEN 'increase'
            ELSE NULL
        END                                                AS standard_change,
        /* latest publication date */
        GREATEST( COALESCE(d1.publication_date,'1900-01-01'::DATE),
                  COALESCE(d2.publication_date,'1900-01-01'::DATE) )
                                                         AS latest_publication_date,
        /* UUIDs per spec ------------------------------------------------ */
        MD5( ARRAY_CONSTRUCT(act_id_1,act_id_2)::STRING )                    AS pair_uuid,
        MD5( OBJECT_CONSTRUCT('activity_id',act_id_1,
                              'smiles',smiles_1)::STRING )                  AS uuid_1,
        MD5( OBJECT_CONSTRUCT('activity_id',act_id_2,
                              'smiles',smiles_2)::STRING )                  AS uuid_2
    FROM  pairs_smiles ps
    LEFT JOIN docs_dates d1 ON TRY_TO_NUMBER(ps.doc_id_1) = d1."doc_id"
    LEFT JOIN docs_dates d2 ON TRY_TO_NUMBER(ps.doc_id_2) = d2."doc_id"
)
/* ----------------------------------------------------------------- */
SELECT *
FROM   pairs_final;