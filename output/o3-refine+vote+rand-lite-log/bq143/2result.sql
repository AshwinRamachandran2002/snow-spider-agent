WITH proteome AS (
  SELECT
    p.sample_id,
    m.sample_submitter_id,      -- sample barcode
    m.sample_type,              -- 'Primary Tumor' / 'Solid Tissue Normal'
    p.gene_symbol,
    p.protein_abundance_log2ratio AS protein_log2ratio
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS p
  JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current`           AS m
       ON p.sample_id = m.sample_id
  WHERE m.sample_type IN ('Primary Tumor','Solid Tissue Normal')
        AND p.gene_symbol IS NOT NULL
),
rna AS (
  SELECT
    sample_barcode                    AS sample_submitter_id,
    gene_name                         AS gene_symbol,
    LOG( fpkm_unstranded + 1 )/LOG(2) AS rna_log2_fpkm,
    sample_type_name                  AS sample_type
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE sample_type_name IN ('Primary Tumor','Solid Tissue Normal')
),
joined AS (
  SELECT
    p.sample_type,
    p.gene_symbol,
    p.protein_log2ratio,
    r.rna_log2_fpkm
  FROM proteome AS p
  JOIN rna      AS r
    ON p.sample_submitter_id = r.sample_submitter_id
   AND p.gene_symbol        = r.gene_symbol
),
gene_correlations AS (
  SELECT
    sample_type,
    gene_symbol,
    CORR(protein_log2ratio, rna_log2_fpkm) AS correlation
  FROM joined
  GROUP BY sample_type, gene_symbol
)
SELECT
  sample_type,
  AVG(correlation) AS average_correlation
FROM gene_correlations
WHERE ABS(correlation) > 0.5
GROUP BY sample_type
ORDER BY sample_type;