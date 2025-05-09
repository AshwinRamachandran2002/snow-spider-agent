WITH gene_corr AS (
  SELECT
    p.gene_symbol,
    r.sample_type_name AS sample_type,
    CORR(
      p.protein_abundance_log2ratio,
      LOG(r.fpkm_unstranded + 1, 2)        -- log2‑transform RNA expression
    ) AS corr_coef
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS p
  JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current` AS m
    ON p.sample_id = m.sample_id
  JOIN `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current` AS r
    ON m.sample_submitter_id = r.sample_barcode
   AND p.gene_symbol          = r.gene_name
  WHERE r.primary_site        = 'Kidney'              -- Clear Cell RCC cohort
    AND r.project_short_name  = 'CPTAC-3'
    AND r.sample_type_name IN ('Primary Tumor',
                               'Solid Tissue Normal')
  GROUP BY p.gene_symbol, sample_type
  HAVING ABS(corr_coef) > 0.5                        -- keep strong correlations
)

SELECT
  sample_type,
  ROUND(AVG(corr_coef), 4) AS average_correlation
FROM gene_corr
GROUP BY sample_type
ORDER BY sample_type;