/* ------------------------------------------------------------
   Correlate protein abundance with RNA-seq expression
   for Clear-Cell RCC (“Primary Tumor” – proteome available)
   ------------------------------------------------------------ */
WITH rna AS (   -- 1. RNA-seq: log2(FPKM+1) for desired sample types
    SELECT  "gene_name"                              AS gene_symbol,
            LOG(2 , "fpkm_unstranded" + 1)           AS log2_fpkm,   -- log2 transform
            "sample_type_name"                       AS sample_type
    FROM    CPTAC_PDC.CPTAC.RNASEQ_HG38_GDC_CURRENT
    WHERE   "sample_type_name" IN ('Primary Tumor','Solid Tissue Normal')
      AND   "fpkm_unstranded" IS NOT NULL
),
proteome AS (  -- 2. Proteome log2-ratio values (study contains only tumor samples)
    SELECT  "gene_symbol"                            AS gene_symbol,
            "protein_abundance_log2ratio"            AS prot_log2ratio,
            'Primary Tumor'                          AS sample_type
    FROM    CPTAC_PDC.CPTAC.QUANT_PROTEOME_CPTAC_CCRCC_DISCOVERY_STUDY_PDC_CURRENT
    WHERE   "protein_abundance_log2ratio" IS NOT NULL
),
joined AS (    -- 3. Pair RNA & proteome measurements by gene & sample type
    SELECT  r.sample_type,
            r.gene_symbol,
            r.log2_fpkm,
            p.prot_log2ratio
    FROM    rna      r
    JOIN    proteome p
           ON r.sample_type = p.sample_type
          AND r.gene_symbol = p.gene_symbol
),
gene_corr AS ( -- 4. Correlation for each gene within the (tumor) sample type
    SELECT  sample_type,
            gene_symbol,
            CORR(prot_log2ratio, log2_fpkm) AS corr_val
    FROM    joined
    GROUP BY sample_type, gene_symbol
    HAVING  ABS(CORR(prot_log2ratio, log2_fpkm)) > 0.5
)
-- 5. Average of strong correlations (|r| > 0.5) per sample type
SELECT  sample_type,
        AVG(corr_val) AS avg_corr_filtered_genes
FROM    gene_corr
GROUP BY sample_type
ORDER BY sample_type;