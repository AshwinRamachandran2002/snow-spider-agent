SELECT
    "case_barcode"                                                      AS case_id,
    LISTAGG(DISTINCT "sample_type_name", ', ')
        WITHIN GROUP (ORDER BY "sample_type_name")                      AS tissue_types
FROM   TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
WHERE  "project_short_name" = 'TCGA-BRCA'
  AND  "gene_type"        = 'protein_coding'
GROUP  BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1
   AND COUNT(DISTINCT CASE WHEN "sample_type_name" = 'Solid Tissue Normal' 
                           THEN 'Solid Tissue Normal' END) = 1
ORDER BY "case_barcode";