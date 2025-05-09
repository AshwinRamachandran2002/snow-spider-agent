/*  Protein–RNA concordance in Clear-Cell RCC (CPTAC)
    -------------------------------------------------
    1)  Pick proteome values from the CCRCC discovery study
        and pull the 5-digit patient code out of each aliquot ID.
    2)  Grab RNA-seq FPKM values for Kidney samples that are either
        “Primary Tumor” or “Solid Tissue Normal”; extract the same
        5-digit patient code from the TCGA/CPTAC sample barcode.
    3)  Join on   (patient_code  +  gene_symbol/name)
    4)  For each gene & sample-type, compute the Pearson correlation
        of protein log2-ratio vs. log2(FPKM+1).
    5)  Keep only genes whose |r| > 0.5  (“strong” concordance)
        and average those r-values within each sample-type.
*/
WITH proteome AS (
  SELECT
      gene_symbol,
      protein_abundance_log2ratio                  AS prot_log2ratio,
      REGEXP_EXTRACT(aliquot_submitter_id,
                     r'(\d{5})\d{4}$')            AS patient_code
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current`
  WHERE protein_abundance_log2ratio IS NOT NULL
),
rna AS (
  SELECT
      sample_type_name                             AS sample_type,
      gene_name,
      fpkm_unstranded,
      REGEXP_EXTRACT(sample_barcode,
                     r'-0?(\d{5})-')              AS patient_code
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE LOWER(primary_site) LIKE '%kidney%'
    AND sample_type_name IN ('Primary Tumor','Solid Tissue Normal')
    AND fpkm_unstranded IS NOT NULL
),
joined AS (
  SELECT
      r.sample_type,
      p.gene_symbol,
      p.prot_log2ratio,
      LOG(r.fpkm_unstranded + 1, 2)               AS rna_log2_fpkm
  FROM proteome p
  JOIN rna      r
    ON p.patient_code = r.patient_code
   AND p.gene_symbol  = r.gene_name
),
gene_corr AS (
  SELECT
      sample_type,
      gene_symbol,
      CORR(prot_log2ratio, rna_log2_fpkm) AS r_val
  FROM joined
  GROUP BY sample_type, gene_symbol
  HAVING ABS(r_val) > 0.5               -- keep only strong correlations
)
SELECT
    sample_type,
    AVG(r_val) AS avg_corr_strong_genes
FROM gene_corr
GROUP BY sample_type
ORDER BY sample_type;