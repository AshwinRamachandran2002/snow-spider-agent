/* ----------------------------------------------------------------
   Generate pairs of 10–15-heavy-atom molecules tested in the same
   (assay, standard_type) that satisfy all requested constraints
-----------------------------------------------------------------*/
WITH /* 1)  Activity rows that meet per-row filters */
activities_filtered AS (
    SELECT
        a."activity_id",
        a."assay_id",
        a."standard_type",
        a."standard_value",
        a."standard_relation",
        a."molregno",
        a."doc_id",
        a."pchembl_value",
        a."potential_duplicate",
        TRY_TO_NUMBER(p."heavy_atoms")            AS heavy_atoms,
        s."canonical_smiles"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."ACTIVITIES_30"       a
    JOIN "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES" p
          ON a."molregno" = p."molregno"
    JOIN "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES" s
          ON a."molregno" = s."molregno"
    WHERE TRY_TO_NUMBER(p."heavy_atoms") BETWEEN 10 AND 15
      AND a."pchembl_value" > 10
      AND a."standard_value" IS NOT NULL
      AND a."standard_relation" = '='
      AND a."potential_duplicate" = 0
),

/* 2)  Keep only (assay, standard_type) with <5 qualifying acts */
assay_counts AS (
    SELECT "assay_id", "standard_type", COUNT(*) AS act_cnt
    FROM   activities_filtered
    GROUP  BY "assay_id", "standard_type"
    HAVING COUNT(*) < 5
),
activities_ready AS (
    SELECT af.*
    FROM   activities_filtered af
    JOIN   assay_counts ac
        ON af."assay_id"      = ac."assay_id"
       AND af."standard_type" = ac."standard_type"
),

/* 3)  Compute synthetic publication date for each document */
docs_ranked AS (
    SELECT
        d."doc_id",
        COALESCE(d."year", 1970)                               AS yr,
        d."journal",
        TRY_TO_NUMBER(d."first_page")                          AS first_pg,
        PERCENT_RANK() OVER (PARTITION BY d."journal", COALESCE(d."year",1970)
                             ORDER BY TRY_TO_NUMBER(d."first_page")) AS pr
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."DOCS" d
),
doc_dates AS (
    SELECT
        "doc_id",
        DATE_FROM_PARTS(
            yr,
            FLOOR(pr*11) + 1,                 -- month 1-12
            MOD(FLOOR(pr*308),28) + 1         -- day   1-28
        ) AS pub_date
    FROM docs_ranked
),

/* 4)  Unordered pairs of DIFFERENT molecules */
pairwise AS (
    SELECT
        a1."activity_id"           AS activity_id_1,
        a2."activity_id"           AS activity_id_2,
        a1."assay_id",
        a1."standard_type",
        a1."standard_value"::FLOAT AS value_1,
        a2."standard_value"::FLOAT AS value_2,
        a1.heavy_atoms             AS heavy_atoms_1,
        a2.heavy_atoms             AS heavy_atoms_2,
        a1."canonical_smiles"      AS smiles_1,
        a2."canonical_smiles"      AS smiles_2,
        a1."doc_id"                AS doc_id_1,
        a2."doc_id"                AS doc_id_2
    FROM activities_ready a1
    JOIN activities_ready a2
      ON a1."assay_id"      = a2."assay_id"
     AND a1."standard_type" = a2."standard_type"
     AND a1."molregno"      <> a2."molregno"
     AND a1."activity_id"   <  a2."activity_id"   -- avoid mirror duplicates
),

/* 5)  Enrich pairs with required computed fields */
pair_enhanced AS (
    SELECT
        p.*,
        GREATEST(p.heavy_atoms_1, p.heavy_atoms_2)         AS max_heavy_atoms,
        GREATEST(dd1.pub_date, dd2.pub_date)               AS latest_pub_date,
        GREATEST(p.doc_id_1, p.doc_id_2)                   AS highest_doc_id,
        CASE
            WHEN p.value_1 > p.value_2 THEN 'decrease'
            WHEN p.value_1 < p.value_2 THEN 'increase'
            ELSE 'no-change'
        END                                               AS standard_change,
        /* UUID based on activity IDs */
        MD5(CONCAT('[', p.activity_id_1, ',', p.activity_id_2, ']')) AS uuid_activity_ids,
        /* UUID based on canonical SMILES */
        MD5(CONCAT('["', p.smiles_1, '","', p.smiles_2, '"]'))       AS uuid_smiles
    FROM pairwise p
    LEFT JOIN doc_dates dd1 ON p.doc_id_1 = dd1."doc_id"
    LEFT JOIN doc_dates dd2 ON p.doc_id_2 = dd2."doc_id"
)

/* 6)  Final output ------------------------------------------------*/
SELECT
    activity_id_1,
    activity_id_2,
    "assay_id",
    "standard_type",
    standard_change,
    uuid_activity_ids,
    uuid_smiles,
    max_heavy_atoms,
    latest_pub_date,
    highest_doc_id
FROM pair_enhanced;