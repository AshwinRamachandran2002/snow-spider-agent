/*  Identify TCGA‐BRCA cases in the hg38 RNA-Seq R35 table that
    1) have rows annotated as protein_coding,
    2) possess more than one distinct RNA-Seq tissue / sample type, and
    3) include at least one “Solid Tissue Normal” sample.  */

WITH pc_brca AS (
    SELECT
        "case_barcode",
        "sample_type_name"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35
    WHERE  "project_short_name" = 'TCGA-BRCA'
      AND  "gene_type"         = 'protein_coding'
)

SELECT
    "case_barcode"
FROM pc_brca
GROUP BY "case_barcode"
HAVING COUNT(DISTINCT "sample_type_name") > 1
   AND SUM( CASE WHEN "sample_type_name" ILIKE '%Solid%Tissue%Normal%' THEN 1 ELSE 0 END ) > 0
ORDER BY "case_barcode";