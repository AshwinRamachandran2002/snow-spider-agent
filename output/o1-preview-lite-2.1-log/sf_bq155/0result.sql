SELECT
    me."mirna_id" AS "miRNA_ID",
    ROUND(
        CORR(
            LOG(10, rge."HTSeq__FPKM" + 1),
            LOG(10, me."reads_per_million_miRNA_mapped" + 1)
        ),
        4
    ) AS "Pearson_Correlation",
    ROUND(
        (
            CORR(
                LOG(10, rge."HTSeq__FPKM" + 1),
                LOG(10, me."reads_per_million_miRNA_mapped" + 1)
            ) * SQRT(COUNT(*) - 2)
        ) / NULLIF(
            SQRT(1 - POWER(
                CORR(
                    LOG(10, rge."HTSeq__FPKM" + 1),
                    LOG(10, me."reads_per_million_miRNA_mapped" + 1)
                ), 2
            )),
            0
        ),
        4
    ) AS "t_statistic",
    COUNT(*) AS "Sample_Size"
FROM
    "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION" AS rge
JOIN
    "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."MIRNASEQ_EXPRESSION" AS me
    ON rge."case_barcode" = me."case_barcode"
JOIN
    "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL" AS c
    ON rge."case_barcode" = c."case_barcode"
WHERE
    rge."gene_name" = 'SNORA31'
    AND c."project_short_name" = 'TCGA-BRCA'
    AND c."age_at_diagnosis" <= 80
    AND c."pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
GROUP BY
    me."mirna_id"
HAVING
    COUNT(*) > 25
    AND ABS(
        CORR(
            LOG(10, rge."HTSeq__FPKM" + 1),
            LOG(10, me."reads_per_million_miRNA_mapped" + 1)
        )
    ) >= 0.3
    AND ABS(
        CORR(
            LOG(10, rge."HTSeq__FPKM" + 1),
            LOG(10, me."reads_per_million_miRNA_mapped" + 1)
        )
    ) < 1.0
ORDER BY
    ABS("Pearson_Correlation") DESC NULLS LAST;