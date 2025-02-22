-- Task: In the TCGA-BRCA cohort of patients who are 80 years old or younger at diagnosis and have a pathological stage of Stage I, Stage II, or Stage IIA, compute for each patient the average log10-transformed RNA-Seq expression levels (using HTSeq__Counts + 1) of the gene SNORA31.

WITH cohort AS (
    SELECT "case_barcode"
    FROM "TCGA_HG38_DATA_V0"."TCGA_BIOCLIN_V0"."CLINICAL"
    WHERE "project_short_name" = 'TCGA-BRCA'
        AND "age_at_diagnosis" <= 80
        AND "pathologic_stage" IN ('Stage I', 'Stage II', 'Stage IIA')
)
SELECT
    "gene_name" AS "symbol",
    AVG(LOG(10, "HTSeq__Counts" + 1)) AS "data",
    "case_barcode" AS "ParticipantBarcode"
FROM "TCGA_HG38_DATA_V0"."TCGA_HG38_DATA_V0"."RNASEQ_GENE_EXPRESSION"
WHERE "case_barcode" IN (SELECT "case_barcode" FROM cohort)
    AND "gene_name" = 'SNORA31'
    AND "HTSeq__Counts" IS NOT NULL
GROUP BY
    "ParticipantBarcode", "symbol";