WITH kirp_expr AS (        -- 1. Pivot CO‑gene expression per KIRP patient
    SELECT
        c."case_barcode",
        c."clinical_stage",
        MAX(CASE WHEN e."gene_name" = 'MT-CO1' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO1",
        MAX(CASE WHEN e."gene_name" = 'MT-CO2' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO2",
        MAX(CASE WHEN e."gene_name" = 'MT-CO3' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL" c
    JOIN "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" e
      ON c."case_barcode" = e."case_barcode"
    WHERE c."disease_code" = 'KIRP'
      AND c."clinical_stage" IS NOT NULL
      AND TRIM(c."clinical_stage") <> ''
      AND e."gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP BY c."case_barcode", c."clinical_stage"
),
-- 2. 90 / 10 split (deterministic) using HASH
splits AS (
    SELECT *,
           ABS(HASH("case_barcode")) % 10 AS "bucket"
    FROM kirp_expr
),
train_data AS (SELECT * FROM splits WHERE "bucket" < 9),
test_data  AS (SELECT * FROM splits WHERE "bucket" = 9),
-- 3. Stage‑specific mean expression (training set)
stage_means AS (
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "AVG_CO1",
        AVG("MT_CO2") AS "AVG_CO2",
        AVG("MT_CO3") AS "AVG_CO3"
    FROM train_data
    GROUP BY "clinical_stage"
),
-- 4. Euclidean distance from each test patient to every stage mean
pred_dist AS (
    SELECT
        t."case_barcode",
        s."clinical_stage" AS "predicted_clinical_stage",
        SQRT(
            POWER(COALESCE(t."MT_CO1",0) - COALESCE(s."AVG_CO1",0), 2) +
            POWER(COALESCE(t."MT_CO2",0) - COALESCE(s."AVG_CO2",0), 2) +
            POWER(COALESCE(t."MT_CO3",0) - COALESCE(s."AVG_CO3",0), 2)
        ) AS "dist"
    FROM test_data t
    CROSS JOIN stage_means s
),
-- 5. Pick the closest stage for each test patient
ranked AS (
    SELECT
        p.*,
        ROW_NUMBER() OVER (PARTITION BY p."case_barcode" ORDER BY p."dist") AS "rn"
    FROM pred_dist p
)
SELECT
    "case_barcode",
    "predicted_clinical_stage"
FROM ranked
WHERE "rn" = 1
ORDER BY "case_barcode";