WITH solid_tissue_normal AS (
    SELECT
        "gene_name",
        "HTSeq__FPKM_UQ"               AS fpkm_uq
    FROM
        TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R28"
    WHERE
        "project_short_name" = 'TCGA-BRCA'
        AND "sample_type_name" = 'Solid Tissue Normal'
        AND "gene_type" = 'protein_coding'
        AND "HTSeq__FPKM_UQ" IS NOT NULL
),
gene_variance AS (
    SELECT
        "gene_name",
        VAR_POP(fpkm_uq)              AS expr_variance,
        COUNT(*)                      AS sample_count
    FROM solid_tissue_normal
    GROUP BY "gene_name"
)
SELECT
    "gene_name",
    expr_variance
FROM
    gene_variance
WHERE
    sample_count > 1
ORDER BY
    expr_variance DESC NULLS LAST,
    "gene_name"
LIMIT 5;