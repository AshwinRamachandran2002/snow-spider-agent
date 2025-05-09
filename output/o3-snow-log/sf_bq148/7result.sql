/*  Top-5 protein-coding genes with the highest variance of
    FPKM-UQ expression in ‘Solid Tissue Normal’ samples of TCGA-BRCA  */

SELECT
    "gene_name",
    VAR_SAMP("fpkm_uq_unstranded") AS "variance_fpkm_uq"
FROM (
        /* Release 40 */
        SELECT  "gene_name",
                "fpkm_uq_unstranded"
        FROM    TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R40
        WHERE   "project_short_name" = 'TCGA-BRCA'
          AND   "sample_type_name"   = 'Solid Tissue Normal'
          AND   "gene_type"          = 'protein_coding'
          AND   "gene_name"          IS NOT NULL
          AND   "fpkm_uq_unstranded" IS NOT NULL

        UNION ALL

        /* Release 39 (some BRCA runs are here) */
        SELECT  "gene_name",
                "fpkm_uq_unstranded"
        FROM    TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R39
        WHERE   "project_short_name" = 'TCGA-BRCA'
          AND   "sample_type_name"   = 'Solid Tissue Normal'
          AND   "gene_type"          = 'protein_coding'
          AND   "gene_name"          IS NOT NULL
          AND   "fpkm_uq_unstranded" IS NOT NULL
) AS stn_brca
GROUP BY
    "gene_name"
HAVING
    COUNT(*) > 1                 -- need at least two values to compute variance
ORDER BY
    "variance_fpkm_uq" DESC NULLS LAST
LIMIT 5;