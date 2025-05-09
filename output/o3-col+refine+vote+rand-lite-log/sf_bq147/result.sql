/* Identify TCGA-BRCA cases that
   1) have RNA-Seq hg38 R35 records limited to protein-coding genes
   2) contain more than one RNA-Seq tissue type
   3) include at least one “Solid Tissue Normal” sample type           */

SELECT
    r."case_barcode"
FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35 AS r
WHERE r."project_short_name" = 'TCGA-BRCA'
  AND r."gene_type" = 'protein_coding'
GROUP BY r."case_barcode"
HAVING COUNT(DISTINCT r."sample_type_name") > 1            -- multiple tissue types
   AND COUNT_IF(r."sample_type_name" ILIKE '%Solid Tissue Normal%') > 0  -- includes STN
ORDER BY r."case_barcode";