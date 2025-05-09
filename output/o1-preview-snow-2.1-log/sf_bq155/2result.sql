WITH temp AS (
    SELECT
        m."mirna_id" AS "miRNA_ID",
        COUNT(*) AS "Sample_Size",
        CORR(LOG(10, r."HTSeq__FPKM" + 1), m."reads_per_million_miRNA_mapped") AS "Pearson_Correlation"
    FROM
        "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL" c
    JOIN
        "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" r
            ON c."case_barcode" = r."case_barcode"
    JOIN
        "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION" m
            ON c."case_barcode" = m."case_barcode"
    WHERE
        c."disease_code" = 'BRCA'
        AND c."age_at_diagnosis" <= 80
        AND c."pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
        AND r."gene_name" = 'SNORA31'
        AND r."HTSeq__FPKM" IS NOT NULL
        AND m."reads_per_million_miRNA_mapped" IS NOT NULL
    GROUP BY
        m."mirna_id"
)
SELECT
    "miRNA_ID",
    ROUND("Pearson_Correlation", 4) AS "Pearson_Correlation",
    ROUND(
        "Pearson_Correlation" * SQRT(("Sample_Size" - 2) / (1 - POWER("Pearson_Correlation", 2))),
        4
    ) AS "t_statistic",
    "Sample_Size"
FROM
    temp
WHERE
    "Sample_Size" > 25
    AND ABS("Pearson_Correlation") >= 0.3
    AND ABS("Pearson_Correlation") < 1.0;