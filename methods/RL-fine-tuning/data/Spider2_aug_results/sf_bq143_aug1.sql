-- Task: Use CPTAC proteomics and RNAseq data for Clear Cell Renal Cell Carcinoma to select 'Primary Tumor' and 'Solid Tissue Normal' samples. Join the datasets on sample submitter IDs and gene symbols. For each gene and sample type, retrieve the protein abundance (log2 ratio) and gene expression levels (log-transformed+1 FPKM). Retrieve the first 100 records.

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
)
SELECT
    m."sample_type" AS "Sample_Type",
    p."gene_symbol" AS "Gene_Symbol",
    p."protein_abundance_log2ratio" AS "Protein_Abundance_Log2Ratio",
    LOG(2, r."fpkm_unstranded" + 1) AS "Log_FPKM"
FROM proteomics_data p
JOIN mapping m ON p."aliquot_submitter_id" = m."aliquot_submitter_id"
JOIN rna_data r ON m."sample_submitter_id" = r."sample_barcode" AND p."gene_symbol" = r."gene_name"
WHERE p."protein_abundance_log2ratio" IS NOT NULL
  AND r."fpkm_unstranded" IS NOT NULL
LIMIT 100;