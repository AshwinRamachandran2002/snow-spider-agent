WITH combined_data AS (
  SELECT
    r.sample_type_name AS Sample_Type,
    UPPER(r.gene_name) AS Gene_Symbol,
    LOG(r.fpkm_unstranded + 1) AS log_expression,
    p.protein_abundance_log2ratio AS protein_abundance
  FROM
    `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current` r
  JOIN
    `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current` m
    ON r.sample_barcode = m.sample_submitter_id
  JOIN
    `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` p
    ON m.sample_id = p.sample_id
  WHERE
    r.sample_type_name IN ('Primary Tumor', 'Solid Tissue Normal')
    AND UPPER(r.gene_name) = UPPER(p.gene_symbol)
    AND r.fpkm_unstranded IS NOT NULL
    AND p.protein_abundance_log2ratio IS NOT NULL
)
SELECT
  Sample_Type,
  ROUND(AVG(Correlation), 4) AS Average_Correlation
FROM (
  SELECT
    Sample_Type,
    Gene_Symbol,
    CORR(log_expression, protein_abundance) AS Correlation
  FROM
    combined_data
  GROUP BY
    Sample_Type, Gene_Symbol
  HAVING
    COUNT(*) >= 3
    AND ABS(CORR(log_expression, protein_abundance)) > 0.5
)
GROUP BY
  Sample_Type