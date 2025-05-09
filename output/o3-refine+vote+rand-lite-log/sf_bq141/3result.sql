WITH clin AS (   -- 1.  keep KIRP patients that have a clinical stage
    SELECT
        "case_barcode",
        "clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'KIRP'
      AND "clinical_stage" IS NOT NULL
), expr AS (     -- 2.  case‑level expression for the three mitochondrial genes
    SELECT
        "case_barcode",
        AVG(CASE WHEN "gene_name" = 'MT-CO3' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO3",
        AVG(CASE WHEN "gene_name" = 'MT-CO1' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO1",
        AVG(CASE WHEN "gene_name" = 'MT-CO2' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO2"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "gene_name" IN ('MT-CO3','MT-CO1','MT-CO2')
    GROUP BY "case_barcode"
), merged AS (   -- 3.  combine clinical + expression and create deterministic split bucket
    SELECT
        c."case_barcode",
        c."clinical_stage",
        e."MT_CO3",
        e."MT_CO1",
        e."MT_CO2",
        MOD(ABS(HASH(c."case_barcode")),10) AS "bucket"   -- equivalent of FARM_FINGERPRINT % 10
    FROM clin  c
    JOIN expr  e  ON c."case_barcode" = e."case_barcode"
), train AS (    -- 4.  90 % of cases
    SELECT * FROM merged WHERE "bucket" < 9
), stage_avg AS ( -- 5.  stage‑specific mean expression vectors (training set)
    SELECT
        "clinical_stage",
        AVG("MT_CO3") AS "avg_MT_CO3",
        AVG("MT_CO1") AS "avg_MT_CO1",
        AVG("MT_CO2") AS "avg_MT_CO2"
    FROM train
    GROUP BY "clinical_stage"
), test AS (     -- 6.  held‑out 10 % of cases
    SELECT * FROM merged WHERE "bucket" = 9
), distance_calc AS (  -- 7.  Euclidean distance from every test case to every stage centroid
    SELECT
        t."case_barcode",
        s."clinical_stage"    AS "stage_candidate",
        SQRT(  POWER(t."MT_CO3" - s."avg_MT_CO3",2)
             + POWER(t."MT_CO1" - s."avg_MT_CO1",2)
             + POWER(t."MT_CO2" - s."avg_MT_CO2",2) )  AS "distance"
    FROM test t
    CROSS JOIN stage_avg s
), ranked AS (   -- 8.  choose the nearest centroid for each test case
    SELECT
        "case_barcode",
        "stage_candidate",
        ROW_NUMBER() OVER (PARTITION BY "case_barcode"
                           ORDER BY "distance" ASC) AS rn
    FROM distance_calc
)
-- 9.  final prediction list
SELECT
    "case_barcode",
    "stage_candidate" AS "predicted_clinical_stage"
FROM ranked
WHERE rn = 1
ORDER BY "case_barcode";