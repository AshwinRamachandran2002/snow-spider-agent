/*  Identify breast-cancer (TCGA-BRCA) cases in the hg38 RNA-seq R35 table
    that (1) have records for protein_coding genes and
    (2) contain RNA-seq samples of two or more different tissue types
        – one of which must be “Solid Tissue Normal”.               */

SELECT
    r."case_barcode"                                          AS "case_barcode",
    COUNT(DISTINCT r."sample_type_name")                      AS "distinct_tissue_type_count",
    LISTAGG(DISTINCT r."sample_type_name", ', ')
        WITHIN GROUP (ORDER BY r."sample_type_name")          AS "tissue_types_present"
FROM
    TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35                        r
JOIN
    TCGA.TCGA_VERSIONED.PER_SAMPLE_FILE_METADATA_HG38_GDC_R39_V2   m
      ON r."case_barcode" = m."case_barcode"
WHERE
      m."project_short_name" = 'TCGA-BRCA'          -- restrict to TCGA breast-cancer project
  AND r."gene_type"        = 'protein_coding'       -- only protein-coding gene rows
GROUP BY
    r."case_barcode"
HAVING
      COUNT(DISTINCT r."sample_type_name") > 1                  -- multiple tissue types
  AND SUM(CASE WHEN r."sample_type_name" = 'Solid Tissue Normal'
               THEN 1 ELSE 0 END) > 0                          -- includes “Solid Tissue Normal”
ORDER BY
    r."case_barcode";