WITH prot AS (
  -- Clear‑cell RCC proteome values and their sample metadata
  SELECT
      m.sample_type,                      -- ‘Primary Tumor’  / ‘Solid Tissue Normal’
      m.sample_submitter_id AS sample_barcode,
      p.gene_symbol,
      p.protein_abundance_log2ratio      AS prot_log2ratio
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current`  p
  JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current`                 m
        ON p.sample_id = m.sample_id
  WHERE m.sample_type IN ('Primary Tumor','Solid Tissue Normal')
),

rna AS (
  -- Matching RNA‑seq expression (log2(FPKM+1)) for kidney samples
  SELECT
      sample_barcode,
      gene_name          AS gene_symbol,
      LOG( fpkm_unstranded + 1 , 2 )     AS expr_log2fpkm,
      sample_type_name   AS sample_type
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE primary_site      = 'Kidney'
    AND sample_type_name IN ('Primary Tumor','Solid Tissue Normal')
),

merged AS (
  -- join proteome and transcriptome on sample and gene
  SELECT
      p.sample_type,       -- will match RNA sample_type
      p.gene_symbol,
      p.prot_log2ratio,
      r.expr_log2fpkm
  FROM prot p
  JOIN rna  r
        ON r.sample_barcode = p.sample_barcode
       AND UPPER(r.gene_symbol) = UPPER(p.gene_symbol)
       AND r.sample_type = p.sample_type
),

gene_corr AS (
  -- per‑gene correlation within each sample class
  SELECT
      sample_type,
      gene_symbol,
      CORR(prot_log2ratio, expr_log2fpkm) AS corr_val
  FROM merged
  GROUP BY sample_type, gene_symbol
),

filtered AS (
  -- keep strong correlations
  SELECT *
  FROM gene_corr
  WHERE ABS(corr_val) > 0.5
)

-- average correlation for each sample class
SELECT
    sample_type,
    AVG(corr_val) AS average_correlation
FROM filtered
GROUP BY sample_type
ORDER BY sample_type;