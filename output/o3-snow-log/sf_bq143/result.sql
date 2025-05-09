/*---------------------------------------------------------------------------
  Compute gene-level Protein-vs-mRNA correlations in CCRCC
  (Primary Tumor vs Solid Tissue Normal) and report the average correlation
  for each sample type after keeping only |r| > 0.5.
---------------------------------------------------------------------------*/
WITH filtered_rna AS (          -- 1. RNA-Seq: keep desired sample types
    SELECT
        "sample_barcode"                      AS sample_uid,            -- RNA sample ID
        "gene_name"                           AS gene_symbol,
        LOG(2 , "fpkm_unstranded" + 1)        AS expr_log2_fpkm,        -- log2(FPKM+1)
        "sample_type_name"                    AS sample_type
    FROM CPTAC_PDC.CPTAC."RNASEQ_HG38_GDC_CURRENT"
    WHERE "sample_type_name" IN ('Primary Tumor', 'Solid Tissue Normal')
      AND "fpkm_unstranded" IS NOT NULL
),
filtered_proteome AS (          -- 2. Proteome: keep non-null ratios
    SELECT
        "sample_id"                           AS sample_uid,            -- Proteome sample ID
        "gene_symbol"                         AS gene_symbol,
        "protein_abundance_log2ratio"         AS prot_log2ratio
    FROM CPTAC_PDC.CPTAC."QUANT_PROTEOME_CPTAC_CCRCC_DISCOVERY_STUDY_PDC_CURRENT"
    WHERE "protein_abundance_log2ratio" IS NOT NULL
),
joined_matrix AS (              -- 3. Join on gene symbol (platforms use different IDs)
    SELECT
        r.sample_type,
        r.gene_symbol,
        r.expr_log2_fpkm,
        p.prot_log2ratio
    FROM filtered_rna      r
    JOIN filtered_proteome p
      ON r.gene_symbol = p.gene_symbol
),
per_gene_corr AS (              -- 4. Pearson correlation per (gene, sample_type)
    SELECT
        sample_type,
        gene_symbol,
        CORR(expr_log2_fpkm, prot_log2ratio) AS corr_val
    FROM joined_matrix
    GROUP BY sample_type, gene_symbol
)
SELECT                           -- 5. Average correlation for each sample type
    sample_type,
    AVG(corr_val) AS average_correlation
FROM per_gene_corr
WHERE ABS(corr_val) > 0.5
GROUP BY sample_type
ORDER BY sample_type;