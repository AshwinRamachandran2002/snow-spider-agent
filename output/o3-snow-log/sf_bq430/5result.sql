/* ---------------------------------------------------------------
   Build unordered activity–pairs that meet all specified filters,
   attach synthetic publication dates, and create two UUID fields.
----------------------------------------------------------------- */
WITH eligible AS (                      /* -------- single rows -------- */
    SELECT
        a."activity_id",
        a."assay_id",
        a."standard_type",
        a."standard_value"::FLOAT                         AS sv,
        a."standard_relation",
        a."pchembl_value"::FLOAT                          AS pchembl,
        a."molregno",
        a."doc_id"::INTEGER                               AS DOC_ID,   -- alias is un-quoted → upper-case
        cs."canonical_smiles",
        TRY_TO_NUMBER(cp."heavy_atoms")                   AS HEAVY_ATOMS_INT,
        COUNT(*)  OVER (PARTITION BY a."assay_id", a."molregno")      AS DUP_CNT,
        COUNT(*)  OVER (PARTITION BY a."assay_id", a."standard_type") AS ASSAY_CNT
    FROM   EBI_CHEMBL.EBI_CHEMBL.ACTIVITIES_27           a
    JOIN   EBI_CHEMBL.EBI_CHEMBL.COMPOUND_PROPERTIES     cp
           ON a."molregno" = cp."molregno"
    JOIN   EBI_CHEMBL.EBI_CHEMBL.COMPOUND_STRUCTURES     cs
           ON a."molregno" = cs."molregno"
    WHERE  cp."heavy_atoms" IS NOT NULL
      AND  TRY_TO_NUMBER(cp."heavy_atoms") BETWEEN 10 AND 15
      AND  a."standard_value" IS NOT NULL
      AND  a."standard_relation" = '='
      AND  a."pchembl_value" IS NOT NULL
      AND  a."pchembl_value" > 10
),
filtered AS (                         /* ---- apply duplicate / assay rules ---- */
    SELECT *
    FROM   eligible
    WHERE  DUP_CNT  < 2        -- fewer than 2 duplicate rows per (assay,molregno)
      AND  ASSAY_CNT < 5       -- assay contains < 5 qualifying activities
),
/* ----------- synthetic publication date for every document --------------- */
docs_ranked AS (
    SELECT
        d."doc_id"                                 AS DOC_ID,
        COALESCE(d."journal", 'UNKNOWN')           AS JOURNAL,
        COALESCE(d."year",    1970)                AS YR,
        TRY_TO_NUMBER(NULLIF(d."first_page", ''))  AS FIRST_PG,
        PERCENT_RANK() OVER (
            PARTITION BY COALESCE(d."journal", 'UNKNOWN'),
                         COALESCE(d."year",    1970)
            ORDER BY TRY_TO_NUMBER(NULLIF(d."first_page", ''))
        )                                          AS PR
    FROM   EBI_CHEMBL.EBI_CHEMBL.DOCS_29 d
),
doc_dates AS (
    SELECT
        DOC_ID,
        YR,
        COALESCE(FLOOR(PR * 11)  + 1, 1)                         AS PUB_MONTH,
        COALESCE(MOD(FLOOR(PR * 308), 28) + 1, 1)                AS PUB_DAY,
        DATE_FROM_PARTS(YR,
                        COALESCE(FLOOR(PR * 11)  + 1, 1),
                        COALESCE(MOD(FLOOR(PR * 308), 28) + 1, 1)) AS PUB_DATE
    FROM   docs_ranked
)
/* ------------------------ unordered activity pairs ----------------------- */
SELECT
       f1."activity_id"                                  AS activity_a,
       f2."activity_id"                                  AS activity_b,
       f1."assay_id",
       f1."standard_type",
       CASE
           WHEN f1.SV > f2.SV THEN 'decrease'
           WHEN f1.SV < f2.SV THEN 'increase'
           ELSE 'no-change'
       END                                               AS change_class,
       GREATEST(f1.HEAVY_ATOMS_INT, f2.HEAVY_ATOMS_INT)  AS max_heavy_atoms,
       GREATEST(dd1.PUB_DATE, dd2.PUB_DATE)              AS latest_publication_date,
       GREATEST(f1.DOC_ID,    f2.DOC_ID)                 AS highest_doc_id,
       MD5(TO_JSON(ARRAY_CONSTRUCT(f1."activity_id", f2."activity_id")))
                                                        AS uuid_from_activities,
       MD5(TO_JSON(ARRAY_CONSTRUCT(f1."canonical_smiles", f2."canonical_smiles")))
                                                        AS uuid_from_smiles
FROM   filtered f1
JOIN   filtered f2
       ON  f1."assay_id"      = f2."assay_id"
       AND f1."standard_type" = f2."standard_type"
       AND f1."activity_id"  < f2."activity_id"      -- enforce unordered pair
       AND f1."molregno"     <> f2."molregno"        -- different molecules
JOIN   doc_dates dd1  ON dd1.DOC_ID = f1.DOC_ID
JOIN   doc_dates dd2  ON dd2.DOC_ID = f2.DOC_ID;