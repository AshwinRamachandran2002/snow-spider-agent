WITH brca_solid_tissue_normal AS (
    SELECT
        "gene_name",
        "HTSeq__FPKM_UQ"      AS "fpkm_uq"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28
    WHERE
        "project_short_name" = 'TCGA-BRCA'
        AND "sample_type_name" = 'Solid Tissue Normal'
        AND "gene_type" = 'protein_coding'
),
gene_variance AS (
    SELECT
        "gene_name",
        VAR_SAMP("fpkm_uq")  AS "fpkm_uq_variance"
    FROM brca_solid_tissue_normal
    GROUP BY "gene_name"
)
SELECT
    "gene_name",
    "fpkm_uq_variance"
FROM gene_variance
ORDER BY
    "fpkm_uq_variance" DESC NULLS LAST,
    "gene_name"        ASC
LIMIT 5;