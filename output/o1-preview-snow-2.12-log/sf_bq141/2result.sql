WITH clinical AS (
    SELECT "case_barcode", "clinical_stage"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
    WHERE "disease_code" = 'KIRP' AND "clinical_stage" IS NOT NULL
),
expr AS (
    SELECT e."case_barcode", e."gene_name", e."HTSeq__FPKM_UQ"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" e
    WHERE e."gene_name" IN ('MT-CO3', 'MT-CO1', 'MT-CO2')
),
data AS (
    SELECT c."case_barcode", c."clinical_stage",
           e."gene_name", e."HTSeq__FPKM_UQ"
    FROM clinical c
    INNER JOIN expr e ON c."case_barcode" = e."case_barcode"
),
pivoted AS (
    SELECT "case_barcode", "clinical_stage",
           MAX(CASE WHEN "gene_name" = 'MT-CO1' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO1",
           MAX(CASE WHEN "gene_name" = 'MT-CO2' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO2",
           MAX(CASE WHEN "gene_name" = 'MT-CO3' THEN "HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM data
    GROUP BY "case_barcode", "clinical_stage"
),
split_data AS (
    SELECT *,
           MOD(TO_NUMBER(SUBSTR(MD5("case_barcode"), 1, 15), 'XXXXXXXXXXXXXXXXX'), 10) AS hash_mod_10
    FROM pivoted
),
train AS (
    SELECT *
    FROM split_data
    WHERE hash_mod_10 < 9
),
test AS (
    SELECT *
    FROM split_data
    WHERE hash_mod_10 >= 9
),
stage_averages AS (
    SELECT "clinical_stage",
           AVG("MT_CO1") AS avg_MT_CO1,
           AVG("MT_CO2") AS avg_MT_CO2,
           AVG("MT_CO3") AS avg_MT_CO3
    FROM train
    GROUP BY "clinical_stage"
),
test_with_distances AS (
    SELECT t."case_barcode",
           sa."clinical_stage" AS predicted_clinical_stage,
           SQRT(
               POWER(t."MT_CO1" - sa.avg_MT_CO1, 2) +
               POWER(t."MT_CO2" - sa.avg_MT_CO2, 2) +
               POWER(t."MT_CO3" - sa.avg_MT_CO3, 2)
           ) AS distance
    FROM test t
    CROSS JOIN stage_averages sa
),
assigned_stage AS (
    SELECT "case_barcode", predicted_clinical_stage,
           ROW_NUMBER() OVER (PARTITION BY "case_barcode" ORDER BY distance ASC) AS rn
    FROM test_with_distances
)
SELECT "case_barcode", predicted_clinical_stage AS "predicted_clinical_stage"
FROM assigned_stage
WHERE rn = 1;