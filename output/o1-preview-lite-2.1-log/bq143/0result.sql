SELECT
  sample_type_name AS Sample_Type,
  ROUND(AVG(corr_value), 4) AS Average_Correlation
FROM (
  SELECT
    gene_symbol,
    sample_type_name,
    CORR(protein_abundance_log2ratio, log_fpkm) AS corr_value
  FROM (
    SELECT
      p.sample_id,
      s.sample_submitter_id,
      r.sample_barcode,
      r.sample_type_name,
      p.gene_symbol,
      p.protein_abundance_log2ratio,
      LOG(r.fpkm_unstranded + 1) AS log_fpkm
    FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS p
    JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current` AS s
      ON p.sample_id = s.sample_id
    JOIN `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current` AS r
      ON s.sample_submitter_id = r.sample_barcode
    WHERE r.primary_site = 'Kidney'
      AND r.sample_type_name IN ('Primary Tumor', 'Solid Tissue Normal')
      AND p.gene_symbol = r.gene_name
  )
  GROUP BY gene_symbol, sample_type_name
  HAVING ABS(CORR(protein_abundance_log2ratio, log_fpkm)) > 0.5
) AS correlations
GROUP BY sample_type_name
ORDER BY sample_type_name;