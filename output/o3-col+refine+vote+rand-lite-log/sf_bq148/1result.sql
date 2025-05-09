WITH stn_samples AS (
    -- solid-tissue-normal sample barcodes for TCGA-BRCA
    SELECT DISTINCT "sample_barcode"
    FROM TCGA.TCGA_VERSIONED."PER_SAMPLE_FILE_METADATA_HG38_GDC_R36"
    WHERE "project_short_name" = 'TCGA-BRCA'
      AND "sample_type_name" ILIKE '%Solid%Tissue%Normal%'
),
gene_var AS (
    -- variance of expression across those samples for protein-coding genes
    SELECT
        r."gene_name",
        VAR_SAMP(r."fpkm_uq_unstranded") AS "fpkm_variance"
    FROM TCGA.TCGA_VERSIONED."RNASEQ_HG38_GDC_R40" r
    JOIN stn_samples s
      ON r."sample_barcode" = s."sample_barcode"
    WHERE r."project_short_name" = 'TCGA-BRCA'
      AND r."gene_type" = 'protein_coding'
      AND r."sample_type_name" ILIKE '%Solid%Tissue%Normal%'
    GROUP BY r."gene_name"
)
SELECT
    "gene_name",
    "fpkm_variance"
FROM gene_var
ORDER BY "fpkm_variance" DESC NULLS LAST
LIMIT 5;