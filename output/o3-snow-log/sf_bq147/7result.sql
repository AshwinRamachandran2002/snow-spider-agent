/*  TCGA breast-cancer (TCGA-BRCA) cases that,
    in the hg38 RNA-seq release R35,
    have protein-coding genes AND contain RNA-seq samples
    from more than one tissue type, one of which is
    “Solid Tissue Normal”.
*/
WITH rnaseq_brca AS (
    SELECT
        r."case_barcode",
        r."sample_type_name"
    FROM TCGA.TCGA_VERSIONED.RNASEQ_HG38_GDC_R35               AS r
    JOIN TCGA.TCGA_VERSIONED.PER_SAMPLE_FILE_METADATA_HG38_GDC_R39_V2 AS m
          ON r."case_barcode" = m."case_barcode"
    WHERE m."project_short_name" = 'TCGA-BRCA'
      AND r."gene_type" = 'protein_coding'
),
per_case AS (
    SELECT
        "case_barcode",
        COUNT(DISTINCT "sample_type_name")                              AS sample_type_cnt,
        MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal'
                 THEN 1 ELSE 0 END)                                     AS has_solid_normal
    FROM rnaseq_brca
    GROUP BY "case_barcode"
)
SELECT
    "case_barcode"
FROM per_case
WHERE sample_type_cnt > 1      -- multiple tissue types
  AND has_solid_normal = 1     -- includes Solid Tissue Normal
ORDER BY "case_barcode";