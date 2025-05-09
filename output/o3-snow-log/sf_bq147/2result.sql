/*  TCGA breast-cancer cases (RNA-seq hg38 R35) that
    1) contain protein-coding genes,
    2) come from breast-cancer project (primary_site = 'Breast'),
    3) have RNA-seq samples from more than one tissue type
       AND at least one of those samples is “Solid Tissue Normal”.
*/
SELECT
    "case_barcode"
FROM (
    SELECT
        "case_barcode",
        COUNT(DISTINCT "sample_type_name")              AS "distinct_sample_types",
        MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal'
                 THEN 1 ELSE 0 END)                    AS "has_solid_tissue_normal"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
    WHERE "gene_type"    = 'protein_coding'
      AND "primary_site" = 'Breast'        -- equivalent to project TCGA-BRCA
    GROUP BY "case_barcode"
)
WHERE "distinct_sample_types" > 1
  AND "has_solid_tissue_normal" = 1
ORDER BY "case_barcode";