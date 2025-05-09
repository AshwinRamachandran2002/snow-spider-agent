/* TCGA breast-cancer (TCGA-BRCA) cases that
   – appear in the RNA-seq hg38 R35 table
   – have rows for protein-coding genes
   – have ≥2 distinct RNA-seq sample types for the same case
   – and at least one of those sample types is “Solid Tissue Normal”
*/
SELECT
    r."case_barcode"
FROM
    TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35"                AS r
JOIN
    TCGA.TCGA_VERSIONED."PER_SAMPLE_FILE_METADATA_HG38_GDC_R39_V2" AS m
      ON r."case_barcode" = m."case_barcode"
WHERE
      r."gene_type" = 'protein_coding'
  AND m."project_short_name" = 'TCGA-BRCA'
GROUP BY
    r."case_barcode"
HAVING
      COUNT(DISTINCT r."sample_type_name") >= 2
  AND COUNT(DISTINCT CASE
          WHEN r."sample_type_name" = 'Solid Tissue Normal'
          THEN r."sample_type_name" END) = 1
ORDER BY
    r."case_barcode";