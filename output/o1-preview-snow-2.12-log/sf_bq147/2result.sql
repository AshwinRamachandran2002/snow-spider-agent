SELECT b."case_barcode", LISTAGG(DISTINCT b."sample_type_name", ';') AS "sample_types"
FROM TCGA.TCGA_VERSIONED.BIOSPECIMEN_GDC_2017_02 b
WHERE b."project_short_name" = 'TCGA-BRCA'
  AND b."sample_type_name" IN ('Primary solid Tumor', 'Solid Tissue Normal', 'Blood Derived Normal')
  AND b."case_barcode" IN (
    SELECT DISTINCT r."case_barcode"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R28 r
    WHERE r."project_short_name" = 'TCGA-BRCA'
      AND r."gene_type" = 'protein_coding'
  )
GROUP BY b."case_barcode"
HAVING COUNT(DISTINCT b."sample_type_name") > 1;