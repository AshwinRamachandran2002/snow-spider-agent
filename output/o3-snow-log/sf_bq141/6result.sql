WITH clinical_filtered AS (
    SELECT 
        "case_barcode",
        "clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE "disease_code" = 'KIRP'
      AND "clinical_stage" IS NOT NULL
), gene_expression AS (
    SELECT
        "case_barcode",
        "gene_name",
        AVG("HTSeq__FPKM_UQ") AS expr
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP BY "case_barcode","gene_name"
), patient_matrix AS (
    SELECT
        c."case_barcode",
        c."clinical_stage",
        MAX(CASE WHEN g."gene_name" = 'MT-CO1' THEN g.expr END) AS "MT_CO1",
        MAX(CASE WHEN g."gene_name" = 'MT-CO2' THEN g.expr END) AS "MT_CO2",
        MAX(CASE WHEN g."gene_name" = 'MT-CO3' THEN g.expr END) AS "MT_CO3",
        MOD(ABS(HASH(c."case_barcode")),10) AS hash_mod
    FROM clinical_filtered c
    JOIN gene_expression g
      ON c."case_barcode" = g."case_barcode"
    GROUP BY c."case_barcode", c."clinical_stage"
), training_stage_avgs AS (
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS avg_co1,
        AVG("MT_CO2") AS avg_co2,
        AVG("MT_CO3") AS avg_co3
    FROM patient_matrix
    WHERE hash_mod < 9             -- 90% for training
    GROUP BY "clinical_stage"
), test_prediction AS (
    SELECT
        p."case_barcode",
        a."clinical_stage"        AS predicted_stage,
        SQRT( POWER(p."MT_CO1"-a.avg_co1,2)
            + POWER(p."MT_CO2"-a.avg_co2,2)
            + POWER(p."MT_CO3"-a.avg_co3,2) ) AS dist
    FROM patient_matrix p
    JOIN training_stage_avgs a
      ON 1 = 1
    WHERE p.hash_mod = 9           -- 10% for testing
)
SELECT
    "case_barcode",
    predicted_stage AS "predicted_clinical_stage"
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY "case_barcode" ORDER BY dist ASC) AS rn
    FROM test_prediction
)
WHERE rn = 1;