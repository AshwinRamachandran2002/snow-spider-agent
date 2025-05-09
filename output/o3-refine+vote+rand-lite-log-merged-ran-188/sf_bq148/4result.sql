SELECT 
    "gene_name",
    "expr_var"
FROM (
    SELECT
        "gene_name",
        VAR_SAMP("HTSeq__FPKM_UQ") AS "expr_var"
    FROM
        TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28
    WHERE
        "project_short_name" = 'TCGA-BRCA'
        AND "sample_type_name" = 'Solid Tissue Normal'
        AND "gene_type" = 'protein_coding'
        AND "HTSeq__FPKM_UQ" IS NOT NULL
    GROUP BY
        "gene_name"
)
ORDER BY
    "expr_var" DESC NULLS LAST,
    "gene_name"
LIMIT 5;