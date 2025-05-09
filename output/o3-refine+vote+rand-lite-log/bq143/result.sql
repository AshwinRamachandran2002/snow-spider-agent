WITH proteome AS (
  -- 1. CCRCC proteome values with sample information
  SELECT
    map.sample_submitter_id             AS sample_barcode,
    map.sample_type                     AS sample_type,
    prot.gene_symbol,
    AVG(prot.protein_abundance_log2ratio) AS protein_log2ratio
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS prot
  JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current` AS map
    ON prot.sample_id = map.sample_id
  WHERE map.sample_type IN ('Primary Tumor', 'Solid Tissue Normal')
  GROUP BY sample_barcode, sample_type, gene_symbol
),
rna AS (
  -- 2. Matching CCRCC RNA‑seq expression (log‑transformed FPKM+1)
  SELECT
    sample_barcode,
    sample_type_name                   AS sample_type,
    gene_name                          AS gene_symbol,
    LOG(fpkm_unstranded + 1)           AS log_expr
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE primary_site = 'Kidney'
    AND sample_type_name IN ('Primary Tumor', 'Solid Tissue Normal')
),
combined AS (
  -- 3. Join proteome and transcriptome on sample & gene
  SELECT
    p.sample_type,
    p.gene_symbol,
    p.protein_log2ratio,
    r.log_expr
  FROM proteome p
  JOIN rna      r
    ON  p.sample_barcode = r.sample_barcode
    AND p.gene_symbol    = r.gene_symbol
),
gene_correlations AS (
  -- 4. Gene‑wise correlations per sample type
  SELECT
    sample_type,
    gene_symbol,
    CORR(protein_log2ratio, log_expr) AS corr
  FROM combined
  GROUP BY sample_type, gene_symbol
),
filtered AS (
  -- 5. Keep only strong correlations
  SELECT
    sample_type,
    corr
  FROM gene_correlations
  WHERE ABS(corr) > 0.5
)
-- 6. Average correlation per sample type
SELECT
  sample_type,
  AVG(corr) AS average_strong_correlation
FROM filtered
GROUP BY sample_type
ORDER BY sample_type;