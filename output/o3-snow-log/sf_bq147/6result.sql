/*  TCGA breast-cancer cases (project = TCGA-BRCA) that
    1) appear in the hg38 RNA-seq release R35,
    2) are represented by protein-coding transcripts, and
    3) have ≥2 different RNA-seq tissue types per case, one of which is
       “Solid Tissue Normal”.
*/

SELECT
       r."case_barcode"
FROM   TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35                     r
JOIN   TCGA.TCGA_VERSIONED.PER_SAMPLE_FILE_METADATA_HG38_GDC_R39_V2 m
       ON r."case_barcode" = m."case_barcode"
WHERE  m."project_short_name" = 'TCGA-BRCA'        -- breast-cancer project
  AND  r."gene_type"        = 'protein_coding'     -- only protein-coding genes
GROUP BY
       r."case_barcode"
HAVING COUNT(DISTINCT r."sample_type_name") > 1    -- multiple tissue types
   AND SUM(CASE WHEN r."sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) > 0
ORDER BY
       r."case_barcode";