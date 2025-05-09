-- ccRCC: correlate protein (log2‑ratio) with RNA expression (log2(FPKM+1))
WITH proteome AS (
  SELECT
    p.case_id,
    cm.case_submitter_id               AS case_barcode,          -- e.g. “TCGA‑…”
    p.gene_symbol,
    p.protein_abundance_log2ratio      AS prot_log2ratio
  FROM `isb-cgc-bq.CPTAC.quant_proteome_CPTAC_CCRCC_discovery_study_pdc_current` AS p
  JOIN `isb-cgc-bq.PDC_metadata.case_metadata_current`                             AS cm
        ON p.case_id = cm.case_id                       -- map to submitter barcode
),
rna AS (
  SELECT
    case_barcode,
    sample_type_name                   AS sample_type,           -- Primary / Normal
    gene_name                          AS gene_symbol,
    LOG(fpkm_unstranded + 1) / LOG(2)  AS rna_log2               -- log2(FPKM+1)
  FROM `isb-cgc-bq.CPTAC.RNAseq_hg38_gdc_current`
  WHERE primary_site      = 'Kidney'
    AND sample_type_name IN ('Primary Tumor','Solid Tissue Normal')
),
joined AS (                       -- pair proteome & RNA by case & gene
  SELECT
    r.sample_type,
    r.gene_symbol,
    p.prot_log2ratio,
    r.rna_log2
  FROM   rna      r
  JOIN   proteome p
         ON r.case_barcode = p.case_barcode
        AND r.gene_symbol = p.gene_symbol
),
gene_corr AS (                    -- Pearson ρ per gene & sample‑type
  SELECT
    sample_type,
    gene_symbol,
    CORR(prot_log2ratio , rna_log2) AS corr_val
  FROM joined
  GROUP BY sample_type, gene_symbol
  HAVING corr_val IS NOT NULL
),
filtered AS (                     -- keep strong correlations
  SELECT *
  FROM   gene_corr
  WHERE  ABS(corr_val) > 0.5
)
SELECT
  sample_type,
  AVG(corr_val) AS avg_correlation
FROM filtered
GROUP BY sample_type
ORDER BY sample_type;