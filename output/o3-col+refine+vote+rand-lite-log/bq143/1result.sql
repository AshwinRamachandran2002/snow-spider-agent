/* --------------------------------------------------------------------
   Clear Cell Renal Cell Carcinoma (CCRCC)
   RNA-seq   vs   Proteome
   --------------------------------------------------------------------
   1)  Kidney RNA-seq (“Primary Tumor”, “Solid Tissue Normal”)
         ‑- keep FPKM >-0 and log10-transform.
   2)  CCRCC discovery proteome (log2 ratios).
   3)  Join on  gene_symbol  (sample IDs do not overlap).
   4)  For every   gene × sample_type   compute Pearson correlation
       across all paired RNA / protein values (needs ≥2 points).
   5)  Keep correlations with |corr| > 0.5.
   6)  Report the mean correlation (rounded to 4 d.p.) for each
       sample_type; still emit a row even if no genes pass the filter.
   ------------------------------------------------------------------ */

WITH
/* ----------  RNA-seq : Kidney only  ------------------------------- */
rna AS (
  SELECT
    sample_barcode             AS rna_sample_id,
    gene_name                  AS gene_symbol,
    LOG10(fpkm_unstranded + 1) AS expr_value,
    sample_type_name           AS sample_type
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE primary_site = 'Kidney'
    AND sample_type_name IN ('Primary Tumor','Solid Tissue Normal')
),

/* ----------  Proteome : CCRCC discovery  -------------------------- */
prot AS (
  SELECT
    aliquot_submitter_id       AS prot_sample_id,
    gene_symbol,
    protein_abundance_log2ratio AS prot_value
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current`
  WHERE protein_abundance_log2ratio IS NOT NULL
),

/* ----------  Join on gene_symbol  --------------------------------- */
joined AS (
  SELECT
    r.sample_type,
    r.gene_symbol,
    r.expr_value,
    p.prot_value
  FROM rna AS r
  JOIN prot AS p
    USING (gene_symbol)
),

/* ----------  Gene-level correlations per sample_type -------------- */
gene_corr AS (
  SELECT
    sample_type,
    gene_symbol,
    CORR(expr_value, prot_value) AS corr
  FROM joined
  GROUP BY sample_type, gene_symbol
  HAVING COUNT(*) > 1          -- need at least two paired points
),

/* ----------  Retain strong correlations  ------------------------- */
strong_corr AS (
  SELECT *
  FROM gene_corr
  WHERE ABS(corr) > 0.5
),

/* ----------  Average correlation per sample_type  ---------------- */
avg_corr AS (
  SELECT
    sample_type,
    AVG(corr) AS mean_corr
  FROM strong_corr
  GROUP BY sample_type
),

/* ----------  Ensure both sample_types appear in output ----------- */
all_types AS (
  SELECT DISTINCT sample_type
  FROM rna
)

/* ----------  Final result  --------------------------------------- */
SELECT
  t.sample_type,
  ROUND(a.mean_corr, 4) AS avg_correlation
FROM all_types AS t
LEFT JOIN avg_corr AS a
USING (sample_type)
ORDER BY sample_type;