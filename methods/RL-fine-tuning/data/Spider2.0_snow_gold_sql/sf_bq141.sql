WITH patients AS (
    SELECT "case_barcode", "clinical_stage"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
    WHERE "disease_code" = 'KIRP' AND "clinical_stage" IS NOT NULL
),
split_patients AS (
    SELECT 
        p."case_barcode", 
        p."clinical_stage",
        MOD(ABS(HASH(p."case_barcode")),10) AS "modulo_10",
        CASE
            WHEN MOD(ABS(HASH(p."case_barcode")),10) < 9 THEN 'train'
            ELSE 'test'
        END AS "split"
    FROM patients p
),
gene_expressions AS (
    SELECT
        r."case_barcode",
        MAX(CASE WHEN r."gene_name" = 'MT-CO1' THEN r."HTSeq__FPKM_UQ" END) AS "MT_CO1_expression",
        MAX(CASE WHEN r."gene_name" = 'MT-CO2' THEN r."HTSeq__FPKM_UQ" END) AS "MT_CO2_expression",
        MAX(CASE WHEN r."gene_name" = 'MT-CO3' THEN r."HTSeq__FPKM_UQ" END) AS "MT_CO3_expression"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" r
    WHERE r."gene_name" IN ('MT-CO1', 'MT-CO2', 'MT-CO3')
    GROUP BY r."case_barcode"
),
patient_data AS (
    SELECT 
        sp."case_barcode",
        sp."clinical_stage",
        sp."split",
        ge."MT_CO1_expression",
        ge."MT_CO2_expression",
        ge."MT_CO3_expression"
    FROM split_patients sp
    JOIN gene_expressions ge ON sp."case_barcode" = ge."case_barcode"
),
stage_averages AS (
    SELECT 
        "clinical_stage",
        AVG("MT_CO1_expression") AS avg_MT_CO1_expression,
        AVG("MT_CO2_expression") AS avg_MT_CO2_expression,
        AVG("MT_CO3_expression") AS avg_MT_CO3_expression
    FROM patient_data
    WHERE "split" = 'train'
    GROUP BY "clinical_stage"
),
test_patients AS (
    SELECT *
    FROM patient_data
    WHERE "split" = 'test'
),
patient_distances AS (
    SELECT
        tp."case_barcode",
        sa."clinical_stage" AS predicted_clinical_stage,
        SQRT(
            POWER(tp."MT_CO1_expression" - sa.avg_MT_CO1_expression, 2) +
            POWER(tp."MT_CO2_expression" - sa.avg_MT_CO2_expression, 2) +
            POWER(tp."MT_CO3_expression" - sa.avg_MT_CO3_expression, 2)
        ) AS distance
    FROM test_patients tp
    CROSS JOIN stage_averages sa
),
patient_predictions AS (
    SELECT 
        pd."case_barcode",
        pd.predicted_clinical_stage,
        ROW_NUMBER() OVER (PARTITION BY pd."case_barcode" ORDER BY pd.distance) AS rn
    FROM patient_distances pd
)
SELECT
    pp."case_barcode",
    pp.predicted_clinical_stage
FROM patient_predictions pp
WHERE pp.rn = 1;