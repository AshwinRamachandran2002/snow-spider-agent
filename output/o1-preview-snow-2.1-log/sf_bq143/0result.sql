WITH sample_data AS (
  SELECT
    m."sample_type" AS "Sample_Type",
    p."gene_symbol",
    p."protein_abundance_log2ratio",
    LOG(2, r."fpkm_unstranded" + 1) AS "log_fpkm"
  FROM
    CPTAC_PDC.CPTAC."QUANT_PROTEOME_CPTAC_CCRCC_DISCOVERY_STUDY_PDC_CURRENT" p
  JOIN
    CPTAC_PDC.PDC_METADATA."ALIQUOT_TO_CASE_MAPPING_CURRENT" m
      ON p."sample_id" = m."sample_id"
  JOIN
    CPTAC_PDC.CPTAC."RNASEQ_HG38_GDC_CURRENT" r
      ON m."case_submitter_id" = r."case_barcode"
         AND p."gene_symbol" = r."gene_name"
         AND m."sample_type" = r."sample_type_name"
  WHERE
    m."sample_type" IN ('Primary Tumor', 'Solid Tissue Normal')
    AND r."primary_site" = 'Kidney'
    AND r."sample_type_name" IN ('Primary Tumor', 'Solid Tissue Normal')
    AND p."protein_abundance_log2ratio" IS NOT NULL
    AND r."fpkm_unstranded" IS NOT NULL
)

, gene_correlations AS (
  SELECT
    "Sample_Type",
    "gene_symbol",
    CORR("protein_abundance_log2ratio", "log_fpkm") AS "correlation",
    COUNT(*) AS n
  FROM sample_data
  GROUP BY "Sample_Type", "gene_symbol"
  HAVING n >= 2
)

SELECT
  "Sample_Type",
  ROUND(AVG("correlation"), 4) AS "Average_Correlation"
FROM gene_correlations
WHERE ABS("correlation") <= 0.5
GROUP BY "Sample_Type";