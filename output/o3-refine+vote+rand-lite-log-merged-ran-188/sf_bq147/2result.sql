WITH "BRCA_CASE_TISSUE_COUNTS" AS (
    SELECT
        "case_barcode",
        COUNT(DISTINCT "sample_type_name")                       AS "num_tissue_types",
        MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal'
                 THEN 1 ELSE 0 END)                             AS "has_solid_tissue_normal"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE
        "project_short_name" = 'TCGA-BRCA'
        AND "gene_type" = 'protein_coding'
    GROUP BY
        "case_barcode"
)

SELECT
    "case_barcode"
FROM
    "BRCA_CASE_TISSUE_COUNTS"
WHERE
    "has_solid_tissue_normal" = 1       -- includes Solid Tissue Normal sample
    AND "num_tissue_types" > 1          -- has more than one tissue type
ORDER BY
    "case_barcode";