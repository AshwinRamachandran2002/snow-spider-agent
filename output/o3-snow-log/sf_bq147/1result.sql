WITH rnaseq_brca AS (
    SELECT
        r."case_barcode",
        r."sample_type_name"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R35" r
    JOIN TCGA.TCGA_VERSIONED."PER_SAMPLE_FILE_METADATA_HG38_GDC_R39_V2" m
      ON r."case_barcode" = m."case_barcode"
    WHERE m."project_short_name" = 'TCGA-BRCA'       -- keep only breast-cancer cases
      AND r."gene_type"         = 'protein_coding'   -- keep only protein-coding genes
), agg AS (
    SELECT
        "case_barcode",
        ARRAY_AGG(DISTINCT "sample_type_name")  AS "sample_types",
        COUNT(DISTINCT "sample_type_name")      AS "num_sample_types",
        MAX(CASE WHEN "sample_type_name" = 'Solid Tissue Normal' THEN 1 ELSE 0 END) AS "has_stn"
    FROM rnaseq_brca
    GROUP BY "case_barcode"
)
SELECT
    "case_barcode",
    "sample_types"
FROM agg
WHERE "has_stn" = 1           -- must include Solid Tissue Normal
  AND "num_sample_types" > 1  -- and at least one additional tissue type
ORDER BY "case_barcode";