-- correlation of protein abundance vs. RNA expression for CPTAC Clear Cell Renal Cell Carcinoma
WITH proteome AS (
  SELECT
    m.sample_submitter_id                              AS sample_barcode,
    p.gene_symbol,
    p.protein_abundance_log2ratio
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current`   p
  JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current`                  m
        ON p.sample_id = m.sample_id
  WHERE p.protein_abundance_log2ratio IS NOT NULL
),
rna AS (
  SELECT
    sample_barcode,
    gene_name                                          AS gene_symbol,
    LOG(fpkm_unstranded + 1) / LOG(2)                 AS log2_fpkm,
    sample_type_name
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE primary_site = 'Kidney'
    AND sample_type_name IN ('Primary Tumor', 'Solid Tissue Normal')
    AND fpkm_unstranded IS NOT NULL
),
joined AS (
  SELECT
    r.sample_type_name,
    r.gene_symbol,
    p.protein_abundance_log2ratio,
    r.log2_fpkm
  FROM rna r
  JOIN proteome p
    ON r.sample_barcode = p.sample_barcode
   AND r.gene_symbol   = p.gene_symbol
),
gene_corr AS (
  SELECT
    sample_type_name,
    gene_symbol,
    CORR(protein_abundance_log2ratio, log2_fpkm) AS corr_value
  FROM joined
  GROUP BY sample_type_name, gene_symbol
  HAVING ABS(corr_value) > 0.5
)
SELECT
  sample_type_name,
  AVG(corr_value) AS avg_correlation
FROM gene_corr
GROUP BY sample_type_name
ORDER BY sample_type_name;