WITH brca_protein AS (
    SELECT
        "case_barcode",
        "sample_type_name"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "gene_type"        = 'protein_coding'
),
eligible_cases AS (
    SELECT
        "case_barcode"
    FROM brca_protein
    GROUP BY "case_barcode"
    HAVING COUNT(DISTINCT "sample_type_name") > 1
       AND MAX(CASE WHEN "sample_type_name" ILIKE '%Solid Tissue Normal%' THEN 1 ELSE 0 END) = 1
)
SELECT
    ec."case_barcode",
    LISTAGG(DISTINCT bp."sample_type_name", ', ') 
        WITHIN GROUP (ORDER BY bp."sample_type_name") AS "sample_types"
FROM eligible_cases ec
JOIN brca_protein bp
  ON ec."case_barcode" = bp."case_barcode"
GROUP BY ec."case_barcode"
ORDER BY ec."case_barcode";