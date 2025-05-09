/* -------------------------------------------------------------------------
   Build activity-pairs that satisfy all requested constraints (Snowflake SQL)
   -------------------------------------------------------------------------*/
WITH docs AS (                    /* raw document metadata ------------------*/
    SELECT  "doc_id",
            COALESCE(TRY_TO_NUMBER("year"), 1970)           AS pub_year,
            "journal",
            TRY_TO_NUMBER("first_page")                     AS first_page
    FROM    "EBI_CHEMBL"."EBI_CHEMBL"."DOCS_29"
),
doc_rank AS (                  /* percent-rank inside each (journal , year) --*/
    SELECT  "doc_id",
            pub_year,
            "journal",
            first_page,
            PERCENT_RANK() OVER (
                 PARTITION BY "journal", pub_year
                 ORDER BY first_page
            )                                              AS pr
    FROM    docs
),
doc_dates AS (                 /* synthetic publication date yyyy-mm-dd ------*/
    SELECT  "doc_id",
            TO_DATE(
              TO_CHAR(pub_year, 'FM9999')                        || '-' ||
              LPAD( TO_CHAR( FLOOR(COALESCE(pr,0)*11) + 1 ), 2,'0') || '-' ||
              LPAD( TO_CHAR( MOD(FLOOR(COALESCE(pr,0)*308),28) + 1 ), 2,'0')
            )                                              AS pub_date
    FROM    doc_rank
),
qual AS (                      /* activities that meet numeric / atom filters */
    SELECT  a."activity_id",
            a."assay_id",
            a."molregno",
            a."doc_id",
            a."standard_type",
            TRY_TO_NUMBER(a."standard_value")              AS std_val,
            a."standard_relation"                          AS rel,
            TRY_TO_NUMBER(a."pchembl_value")               AS pchembl,
            a."potential_duplicate"                        AS dup_flag,
            TRY_TO_NUMBER(p."heavy_atoms")                 AS heavy_atoms,
            s."canonical_smiles"
    FROM    "EBI_CHEMBL"."EBI_CHEMBL"."ACTIVITIES_27"        a
    JOIN    "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES"  p
           ON a."molregno" = p."molregno"
    JOIN    "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES"  s
           ON a."molregno" = s."molregno"
    WHERE   TRY_TO_NUMBER(p."heavy_atoms") BETWEEN 10 AND 15
      AND   TRY_TO_NUMBER(a."pchembl_value")  > 10
      AND   a."standard_value"                IS NOT NULL
      AND   a."standard_relation" IN ('=','<','>','<=','>=')
),
assay_ok AS (                  /* assays with <5 activities & <2 duplicates --*/
    SELECT  "assay_id",
            "standard_type"
    FROM    qual
    GROUP BY "assay_id", "standard_type"
    HAVING  COUNT(*) < 5
       AND  SUM(CASE WHEN dup_flag = '1' THEN 1 ELSE 0 END) < 2
),
filtered AS (                  /* attach synthetic publication date ----------*/
    SELECT  q.*,
            d.pub_date
    FROM    qual           q
    JOIN    assay_ok       ok  ON q."assay_id"      = ok."assay_id"
                              AND q."standard_type" = ok."standard_type"
    LEFT JOIN doc_dates    d   ON q."doc_id"        = d."doc_id"
),
pairs AS (                     /* unordered pairs within same assay / type ---*/
    SELECT  f1."activity_id"                              AS act_id_1,
            f2."activity_id"                              AS act_id_2,
            f1."assay_id",
            f1."standard_type",
            f1.std_val                                    AS val_1,
            f1.rel                                        AS rel_1,
            f2.std_val                                    AS val_2,
            f2.rel                                        AS rel_2,
            GREATEST(f1.heavy_atoms, f2.heavy_atoms)      AS max_heavy_atoms,
            CASE WHEN f1.pub_date >= f2.pub_date
                 THEN f1.pub_date ELSE f2.pub_date END    AS latest_pub_date,
            GREATEST(f1."doc_id", f2."doc_id")            AS max_doc_id,
            f1."canonical_smiles"                         AS smiles_1,
            f2."canonical_smiles"                         AS smiles_2
    FROM    filtered f1
    JOIN    filtered f2
           ON f1."assay_id"      = f2."assay_id"
          AND f1."standard_type" = f2."standard_type"
          AND f1."activity_id"   < f2."activity_id"
),
final AS (                    /* change class + UUIDs ------------------------*/
    SELECT  act_id_1,
            act_id_2,
            "assay_id",
            "standard_type",
            val_1,
            rel_1,
            val_2,
            rel_2,
            max_heavy_atoms,
            latest_pub_date,
            max_doc_id,
            CASE
              WHEN rel_1='=' AND rel_2='=' AND val_1 = val_2 THEN 'no-change'
              WHEN val_1 > val_2                             THEN 'decrease'
              WHEN val_1 < val_2                             THEN 'increase'
              ELSE 'no-change'
            END                                             AS std_change,
            UPPER(MD5('[' || act_id_1 || ',' || act_id_2 || ']'))
                                                           AS uuid_activity_pair,
            UPPER(MD5('[' || smiles_1  || ',' || smiles_2  || ']'))
                                                           AS uuid_smiles_pair
    FROM    pairs
)
SELECT *
FROM   final
ORDER  BY latest_pub_date DESC NULLS LAST
LIMIT  100;