SELECT
    "case_barcode"
FROM (
    SELECT
        "case_barcode",
        COUNT(DISTINCT "sample_type_name")               AS "distinct_sample_types",
        MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) AS "has_solid_tissue_normal"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE
        "project_short_name" = 'TCGA-BRCA'
        AND "gene_type"       = 'protein_coding'
    GROUP BY
        "case_barcode"
)
WHERE
      "has_solid_tissue_normal" = 1        -- must include Solid Tissue Normal
  AND "distinct_sample_types"   > 1        -- must have >1 tissue type within the case
ORDER BY
    "case_barcode";