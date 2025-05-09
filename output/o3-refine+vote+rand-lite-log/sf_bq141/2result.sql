-- 1)  pick KIRP patients with a valid clinical stage
-- 2)  gather FPKM‑UQ expression for MT‑CO1, MT‑CO2, MT‑CO3
-- 3)  pivot the three genes into wide form
-- 4)  HASH‑based 90 : 10 split (≈ BigQuery FARM_FINGERPRINT)
-- 5)  build stage‑specific averages from the training set
-- 6)  for every test patient pick the stage whose centroid is closest
-- 7)  return the predictions
WITH kirp_patients AS (   -------------------------------------------------- ①
    SELECT DISTINCT
           "case_barcode",
           "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "disease_code" = 'KIRP'
      AND  "clinical_stage" IS NOT NULL
),
expr_raw AS (             -------------------------------------------------- ②
    SELECT
        e."case_barcode",
        e."gene_name",
        e."HTSeq__FPKM_UQ"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"  e
    JOIN   kirp_patients  p
           ON e."case_barcode" = p."case_barcode"
    WHERE  e."gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
),
expr_pivot AS (           -------------------------------------------------- ③
    SELECT
        "case_barcode",
        AVG(CASE WHEN "gene_name" = 'MT-CO1' THEN "HTSeq__FPKM_UQ" END) AS "mtco1",
        AVG(CASE WHEN "gene_name" = 'MT-CO2' THEN "HTSeq__FPKM_UQ" END) AS "mtco2",
        AVG(CASE WHEN "gene_name" = 'MT-CO3' THEN "HTSeq__FPKM_UQ" END) AS "mtco3"
    FROM expr_raw
    GROUP BY "case_barcode"
),
patient_data AS (         -------------------------------------------------- ④
    SELECT
        p."case_barcode",
        p."clinical_stage",
        e."mtco1",
        e."mtco2",
        e."mtco3",
        MOD(ABS(HASH(p."case_barcode")),10)               AS "bucket"   -- HASH ≈ FARM_FINGERPRINT
    FROM   kirp_patients  p
    JOIN   expr_pivot     e
           ON p."case_barcode" = e."case_barcode"
),
training AS (SELECT * FROM patient_data WHERE "bucket" < 9),   -- 90 %
test     AS (SELECT * FROM patient_data WHERE "bucket" >= 9),   -- 10 %

stage_avg AS (            -------------------------------------------------- ⑤
    SELECT
        "clinical_stage",
        AVG("mtco1") AS "avg_mtco1",
        AVG("mtco2") AS "avg_mtco2",
        AVG("mtco3") AS "avg_mtco3"
    FROM training
    GROUP BY "clinical_stage"
),
distance_calc AS (        -------------------------------------------------- ⑥
    SELECT
        t."case_barcode",
        s."clinical_stage"                                    AS "stage_candidate",
        SQRT(
            POWER(t."mtco1" - s."avg_mtco1",2) +
            POWER(t."mtco2" - s."avg_mtco2",2) +
            POWER(t."mtco3" - s."avg_mtco3",2)
        )                                                    AS "dist"
    FROM test t
    CROSS JOIN stage_avg s
),
predicted AS (
    SELECT
        "case_barcode",
        "stage_candidate" AS "predicted_clinical_stage"
    FROM (
        SELECT
            "case_barcode",
            "stage_candidate",
            "dist",
            ROW_NUMBER() OVER (PARTITION BY "case_barcode"
                               ORDER BY "dist" ASC) AS rn
        FROM distance_calc
    )
    WHERE rn = 1
)
SELECT
    "case_barcode",
    "predicted_clinical_stage"
FROM   predicted
ORDER BY "case_barcode";