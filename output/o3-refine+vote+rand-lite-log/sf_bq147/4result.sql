WITH filtered AS (
    SELECT
        "case_barcode",
        "sample_type_name"
    FROM
        TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE
        "project_short_name" = 'TCGA-BRCA'
        AND "gene_type" = 'protein_coding'
),
per_case AS (
    SELECT
        "case_barcode",
        COUNT(DISTINCT "sample_type_name")                AS tissue_type_count,
        MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) AS has_solid_tissue_normal
    FROM
        filtered
    GROUP BY
        "case_barcode"
)
SELECT
    "case_barcode"
FROM
    per_case
WHERE
    has_solid_tissue_normal = 1
    AND tissue_type_count > 1
ORDER BY
    "case_barcode";