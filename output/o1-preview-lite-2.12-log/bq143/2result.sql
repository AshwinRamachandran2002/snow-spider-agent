SELECT
  Sample_Type,
  ROUND(AVG(correlation), 4) AS Average_Correlation
FROM (
  SELECT
    m.sample_type AS Sample_Type,
    p.gene_symbol,
    CORR(p.protein_abundance_log2ratio, LOG(r.fpkm_unstranded + 1)) AS correlation
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS p
  JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current` AS m
    ON p.sample_id = m.sample_id
  JOIN `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current` AS r
    ON m.sample_submitter_id = r.sample_barcode
    AND p.gene_symbol = r.gene_name
  WHERE
    m.sample_type IN ('Primary Tumor', 'Solid Tissue Normal')
    AND r.sample_type_name IN ('Primary Tumor', 'Solid Tissue Normal')
    AND p.protein_abundance_log2ratio IS NOT NULL
    AND r.fpkm_unstranded IS NOT NULL
  GROUP BY Sample_Type, p.gene_symbol
  HAVING ABS(correlation) > 0.5
)
GROUP BY Sample_Type;