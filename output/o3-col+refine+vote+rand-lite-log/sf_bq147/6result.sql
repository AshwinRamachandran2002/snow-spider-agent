/*  Identify TCGA-BRCA cases that
    • are present in the hg38 R35 RNA-Seq table
    • have measurements for protein-coding genes
    • contain RNA-Seq samples drawn from more than one tissue type
    • include at least one “Solid Tissue Normal” sample type
*/
SELECT
    "case_barcode",
    COUNT(DISTINCT "sample_type_name")                                    AS "num_sample_types",
    LISTAGG(DISTINCT "sample_type_name", ', ')
         WITHIN GROUP (ORDER BY "sample_type_name")                       AS "sample_types_present"
FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
WHERE "project_short_name" = 'TCGA-BRCA'
  AND "gene_type"         = 'protein_coding'
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1
   AND MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) = 1
ORDER BY "case_barcode";