WITH gene_expression AS (
    SELECT "case_barcode", "gene_name", "HTSeq__FPKM_UQ"
    FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
    WHERE "gene_name" IN ('MT-CO3', 'MT-CO1', 'MT-CO2')
),
clinical_gene_data AS (
    SELECT
        c."case_barcode",
        c."clinical_stage",
        MAX(CASE WHEN r."gene_name" = 'MT-CO1' THEN r."HTSeq__FPKM_UQ" END) AS "MT_CO1",
        MAX(CASE WHEN r."gene_name" = 'MT-CO2' THEN r."HTSeq__FPKM_UQ" END) AS "MT_CO2",
        MAX(CASE WHEN r."gene_name" = 'MT-CO3' THEN r."HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL" AS c
    JOIN gene_expression AS r
        ON c."case_barcode" = r."case_barcode"
    WHERE c."disease_code" = 'KIRP' AND c."clinical_stage" IS NOT NULL
    GROUP BY c."case_barcode", c."clinical_stage"
),
split_data AS (
    SELECT *,
        MOD(ABS(HASH("case_barcode")), 10) AS "mod_value",
        CASE WHEN MOD(ABS(HASH("case_barcode")), 10) < 9 THEN 'TRAIN' ELSE 'TEST' END AS "dataset"
    FROM clinical_gene_data
),
stage_averages AS (
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "avg_MT_CO1",
        AVG("MT_CO2") AS "avg_MT_CO2",
        AVG("MT_CO3") AS "avg_MT_CO3"
    FROM split_data
    WHERE "dataset" = 'TRAIN'
    GROUP BY "clinical_stage"
),
distance_calculations AS (
    SELECT
        t."case_barcode",
        a."clinical_stage" AS "predicted_clinical_stage",
        SQRT(
            POWER(t."MT_CO1" - a."avg_MT_CO1", 2) +
            POWER(t."MT_CO2" - a."avg_MT_CO2", 2) +
            POWER(t."MT_CO3" - a."avg_MT_CO3", 2)
        ) AS "distance"
    FROM split_data AS t
    CROSS JOIN stage_averages AS a
    WHERE t."dataset" = 'TEST'
),
ranked_distances AS (
    SELECT
        "case_barcode",
        "predicted_clinical_stage",
        ROW_NUMBER() OVER (PARTITION BY "case_barcode" ORDER BY "distance") AS "rn"
    FROM distance_calculations
)
SELECT
    "case_barcode",
    "predicted_clinical_stage"
FROM ranked_distances
WHERE "rn" = 1;