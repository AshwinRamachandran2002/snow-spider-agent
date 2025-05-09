/*  Clear-cell RCC (Kidney) – protein vs. RNA concordance
    ------------------------------------------------------------------
    Steps
      1) Join CCRCC proteome and RNA-seq tables by gene symbol.
      2) Keep Kidney RNA samples of type “Primary Tumor” or
         “Solid Tissue Normal”.
      3) For each gene × sample-type pair with ≥5 matched rows,
         compute Pearson correlation between
         protein log2-ratio and log2(FPKM + 1).
      4) Exclude correlations with |corr| > 0.5.
      5) Report, per sample-type, the mean correlation of
         the retained genes and how many genes contributed.
*/

WITH joined AS (
  SELECT
      p.gene_symbol,
      r.sample_type_name,
      p.protein_abundance_log2ratio AS prot_val,
      LOG(r.fpkm_unstranded + 1, 2) AS rna_val
  FROM  `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS p
  JOIN  `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`                                 AS r
        ON p.gene_symbol = r.gene_name
  WHERE r.primary_site      = 'Kidney'
    AND r.sample_type_name IN ('Primary Tumor', 'Solid Tissue Normal')
    AND p.protein_abundance_log2ratio IS NOT NULL
    AND r.fpkm_unstranded            IS NOT NULL
),

per_gene_corr AS (
  SELECT
      gene_symbol,
      sample_type_name,
      CORR(prot_val, rna_val) AS corr,
      COUNT(*)               AS n_pairs
  FROM joined
  GROUP BY gene_symbol, sample_type_name
  HAVING n_pairs >= 5
         AND corr IS NOT NULL
),

filtered AS (
  SELECT *
  FROM   per_gene_corr
  WHERE  ABS(corr) <= 0.5        -- exclude |corr| > 0.5
)

SELECT
    sample_type_name,
    AVG(corr) AS average_corr_over_genes,
    COUNT(*)  AS n_genes_retained
FROM filtered
GROUP BY sample_type_name
ORDER BY sample_type_name;