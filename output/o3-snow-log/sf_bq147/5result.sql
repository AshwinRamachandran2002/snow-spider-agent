/*  Identify breast-cancer (TCGA-BRCA) cases that
    1) have RNA-seq (hg38 r35) records for protein-coding genes, and
    2) contain more than one distinct tissue type among their RNA-seq samples,
       one of which must be “Solid Tissue Normal”.                                   */

WITH brca_rna AS (
    SELECT DISTINCT
           r."case_barcode",
           r."sample_type_name"
    FROM   "TCGA"."TCGA_VERSIONED"."RNASEQ_HG38_GDC_R35"                    r
    JOIN   "TCGA"."TCGA_VERSIONED"."PER_SAMPLE_FILE_METADATA_HG38_GDC_R39_V2" m
           ON r."case_barcode" = m."case_barcode"
    WHERE  m."project_short_name" = 'TCGA-BRCA'
      AND  r."gene_type"          = 'protein_coding'
)

SELECT
       "case_barcode",
       LISTAGG(DISTINCT "sample_type_name", ', ')
           WITHIN GROUP (ORDER BY "sample_type_name")      AS "sample_type_names",
       COUNT(DISTINCT  "sample_type_name")                 AS "num_sample_types"
FROM   brca_rna
GROUP  BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1
   AND SUM(CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) > 0
ORDER  BY "case_barcode";