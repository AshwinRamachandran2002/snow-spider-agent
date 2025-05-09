WITH clin AS (
    SELECT
        "bcr_patient_barcode" AS "ParticipantBarcode",
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
totals AS (
    SELECT
        "histological_type",
        COUNT(DISTINCT "ParticipantBarcode") AS "total_n"
    FROM clin
    GROUP BY "histological_type"
),
mutated_cases AS (
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
),
mutated_per_hist AS (
    SELECT
        c."histological_type",
        COUNT(DISTINCT c."ParticipantBarcode") AS "mutated_n"
    FROM clin c
    INNER JOIN mutated_cases m
        ON c."ParticipantBarcode" = m."ParticipantBarcode"
    GROUP BY c."histological_type"
),
combined AS (
    SELECT
        t."histological_type",
        t."total_n",
        COALESCE(m."mutated_n", 0) AS "mutated_n",
        COALESCE(m."mutated_n", 0) * 100.0 / t."total_n" AS "mutation_percentage"
    FROM totals t
    LEFT JOIN mutated_per_hist m
        ON t."histological_type" = m."histological_type"
)
SELECT
    "histological_type",
    ROUND("mutation_percentage", 4) AS "mutation_percentage"
FROM combined
ORDER BY "mutation_percentage" DESC NULLS LAST,
         "histological_type"
LIMIT 5;