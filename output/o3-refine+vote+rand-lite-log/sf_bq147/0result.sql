SELECT
  "case_barcode",
  ARRAY_AGG(DISTINCT "sample_type_name") AS "sample_type_names"
FROM
  TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
WHERE
  "project_short_name" = 'TCGA-BRCA'
  AND "gene_type" = 'protein_coding'
GROUP BY
  "case_barcode"
HAVING
  COUNT(DISTINCT "sample_type_name") > 1                    -- multiple tissue types
  AND SUM(IFF("sample_type_name" = 'Solid Tissue Normal',   -- at least one “Solid Tissue Normal”
              1, 0)) > 0
ORDER BY
  "case_barcode";