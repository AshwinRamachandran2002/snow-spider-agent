SELECT
    r."case_barcode",
    ARRAY_AGG(DISTINCT r."sample_type_name")      AS "sample_types_present",
    COUNT(DISTINCT r."sample_type_name")          AS "num_sample_types"
FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"            AS r
JOIN TCGA.TCGA_VERSIONED."PER_SAMPLE_FILE_METADATA_HG38_GDC_R39_V2"  AS m
      ON r."case_barcode" = m."case_barcode"
WHERE m."project_short_name" = 'TCGA-BRCA'          -- Breast-cancer project
  AND r."gene_type"         = 'protein_coding'      -- only protein-coding genes
GROUP BY r."case_barcode"
HAVING COUNT(DISTINCT r."sample_type_name") > 1     -- multiple tissue types
   AND SUM(CASE WHEN r."sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) > 0
ORDER BY r."case_barcode";