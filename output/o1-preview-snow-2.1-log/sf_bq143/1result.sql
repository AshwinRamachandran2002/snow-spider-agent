WITH proteomics_data AS (
    SELECT p."aliquot_submitter_id", LOWER(p."gene_symbol") AS "gene_symbol", p."protein_abundance_log2ratio"
    FROM CPTAC_PDC.CPTAC."QUANT_PROTEOME_CPTAC_CCRCC_DISCOVERY_STUDY_PDC_CURRENT" p
),
mapping AS (
    SELECT m."aliquot_submitter_id", LOWER(TRIM(m."sample_submitter_id")) AS "sample_submitter_id", m."sample_type"
    FROM CPTAC_PDC.PDC_METADATA."ALIQUOT_TO_CASE_MAPPING_CURRENT" m
    WHERE m."sample_submitter_id" IS NOT NULL
      AND m."sample_submitter_id" <> ''
      AND m."sample_type" IN ('Primary Tumor', 'Solid Tissue Normal')
),
rna_data AS (
    SELECT LOWER(TRIM(r."sample_barcode")) AS "sample_barcode", LOWER(r."gene_name") AS "gene_name", r."fpkm_unstranded"
    FROM CPTAC_PDC.CPTAC."RNASEQ_HG38_GDC_CURRENT" r
    WHERE r."primary_site" = 'Kidney'
      AND r."sample_type_name" IN ('Primary Tumor', 'Solid Tissue Normal')
),
joined_data AS (
    SELECT
        m."sample_type",
        p."gene_symbol",
        p."protein_abundance_log2ratio",
        LOG(2, r."fpkm_unstranded" + 1) AS "log_fpkm"
    FROM proteomics_data p
    JOIN mapping m ON p."aliquot_submitter_id" = m."aliquot_submitter_id"
    JOIN rna_data r ON m."sample_submitter_id" = r."sample_barcode" AND p."gene_symbol" = r."gene_name"
    WHERE p."protein_abundance_log2ratio" IS NOT NULL
      AND r."fpkm_unstranded" IS NOT NULL
),
correlations AS (
    SELECT
        "sample_type",
        "gene_symbol",
        CORR("protein_abundance_log2ratio", "log_fpkm") AS correlation_value
    FROM joined_data
    GROUP BY "sample_type", "gene_symbol"
    HAVING COUNT(*) >= 2
),
filtered_correlations AS (
    SELECT *
    FROM correlations
    WHERE ABS(correlation_value) <= 0.5
)
SELECT
    "sample_type" AS "Sample_Type",
    ROUND(AVG(correlation_value), 4) AS "Average_Correlation"
FROM filtered_correlations
GROUP BY "sample_type";