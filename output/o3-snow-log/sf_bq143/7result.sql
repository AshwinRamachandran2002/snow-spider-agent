/*  Correlate proteome vs. RNA-seq in CCRCC (Primary Tumor & Solid Tissue Normal)  */

WITH proteome_agg AS (   -- mean protein log2 ratio per gene & sample
    SELECT
        m."sample_submitter_id"                  AS "sample_barcode",
        m."sample_type"                          AS "sample_type",
        p."gene_symbol"                          AS "gene_symbol",
        AVG(p."protein_abundance_log2ratio")     AS "protein_log2ratio"
    FROM  CPTAC_PDC.CPTAC."QUANT_PROTEOME_CPTAC_CCRCC_DISCOVERY_STUDY_PDC_CURRENT"  p
    JOIN  CPTAC_PDC.PDC_METADATA."ALIQUOT_TO_CASE_MAPPING_CURRENT"                  m
          ON p."aliquot_submitter_id" = m."aliquot_submitter_id"
    WHERE m."sample_type" IN ('Primary Tumor', 'Solid Tissue Normal')
          AND p."protein_abundance_log2ratio" IS NOT NULL
    GROUP BY
        m."sample_submitter_id",
        m."sample_type",
        p."gene_symbol"
),

rna_expr AS (            -- log2(FPKM+1) per gene & sample
    SELECT
        r."sample_barcode"                         AS "sample_barcode",
        r."sample_type_name"                       AS "sample_type",
        r."gene_name"                              AS "gene_symbol",
        LOG(2, r."fpkm_unstranded" + 1)            AS "expr_log2"
    FROM  CPTAC_PDC.CPTAC."RNASEQ_HG38_GDC_CURRENT" r
    WHERE r."sample_type_name" IN ('Primary Tumor', 'Solid Tissue Normal')
          AND r."fpkm_unstranded" IS NOT NULL
),

combined AS (          -- matched proteome & RNA records
    SELECT
        p."sample_type",
        p."gene_symbol",
        p."protein_log2ratio",
        r."expr_log2"
    FROM proteome_agg p
    JOIN rna_expr    r
          ON p."sample_barcode" = r."sample_barcode"
         AND p."gene_symbol"    = r."gene_symbol"
         AND p."sample_type"    = r."sample_type"
),

gene_corr AS (         -- Pearson correlation per gene & sample-type
    SELECT
        "sample_type",
        "gene_symbol",
        CORR("protein_log2ratio", "expr_log2") AS "corr_value"
    FROM combined
    GROUP BY
        "sample_type",
        "gene_symbol"
),

filtered AS (          -- retain strong correlations |r| > 0.5
    SELECT *
    FROM   gene_corr
    WHERE  ABS("corr_value") > 0.5
)

SELECT
    "sample_type",
    AVG("corr_value") AS "avg_correlation"
FROM   filtered
GROUP BY "sample_type"
ORDER BY "sample_type";