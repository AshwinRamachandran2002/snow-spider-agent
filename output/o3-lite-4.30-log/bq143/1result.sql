WITH matched AS (
  /*--------------------------------------------------------------
    Join CCRCC proteome with matching Kidney RNA‑seq records on
    sample barcode and gene symbol; keep Tumor & Normal samples.
  --------------------------------------------------------------*/
  SELECT
      r.sample_type_name                    AS sample_type,          -- 'Primary Tumor' / 'Solid Tissue Normal'
      p.gene_symbol                         AS gene_name,
      p.protein_abundance_log2ratio         AS protein_log2ratio,
      LOG(r.fpkm_unstranded + 1, 2)         AS log2_fpkm             -- log2‑transform RNA expression
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS p
  JOIN `isb-cgc-bq.PDC_metadata.aliquot_to_case_mapping_current`                 AS m
        ON p.sample_id = m.sample_id
  JOIN `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`                                AS r
        ON m.sample_submitter_id = r.sample_barcode      -- same sample
       AND r.gene_name           = p.gene_symbol         -- same gene
  WHERE r.primary_site      = 'Kidney'
    AND r.sample_type_name IN ('Primary Tumor', 'Solid Tissue Normal')
    AND r.fpkm_unstranded IS NOT NULL
),

per_gene_corr AS (
  /*--------------------------------------------------------------
    Compute per‑gene correlations; retain only |r| > 0.5.
  --------------------------------------------------------------*/
  SELECT
      sample_type,
      gene_name,
      CORR(log2_fpkm, protein_log2ratio) AS r_val
  FROM matched
  GROUP BY sample_type, gene_name
  HAVING ABS(r_val) > 0.5
)

/*--------------------------------------------------------------
  Average the retained correlations for each sample type.
--------------------------------------------------------------*/
SELECT
    sample_type,
    ROUND(AVG(r_val), 4) AS average_correlation
FROM per_gene_corr
GROUP BY sample_type
ORDER BY sample_type;