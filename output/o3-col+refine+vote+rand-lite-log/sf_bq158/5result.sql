/*  Top 5 breast-cancer (BRCA) histological sub-types with the highest
    percentage of CDH1-mutated cases in the PanCancer Atlas             */

WITH clinical AS (      -- all BRCA patients with a recorded histology
    SELECT
        "bcr_patient_barcode"            AS patient_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),

totals AS (              -- total BRCA cases per histology
    SELECT
        "histological_type",
        COUNT(DISTINCT patient_id)       AS total_cases
    FROM clinical
    GROUP BY "histological_type"
),

mutated AS (             -- BRCA patients carrying a CDH1 mutation
    SELECT DISTINCT
        c."histological_type",
        c.patient_id
    FROM clinical                                       AS c
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" AS m
      ON c.patient_id = m."ParticipantBarcode"
    WHERE m."Study"       = 'BRCA'
      AND m."Hugo_Symbol" = 'CDH1'
),

mutated_counts AS (      -- number of CDH1-mutated cases per histology
    SELECT
        "histological_type",
        COUNT(DISTINCT patient_id)       AS mutated_cases
    FROM mutated
    GROUP BY "histological_type"
)

SELECT
    t."histological_type",
    ROUND(100.0 * m.mutated_cases / t.total_cases, 2)  AS "cdh1_mutation_pct"
FROM totals            AS t
JOIN mutated_counts    AS m USING ("histological_type")
ORDER BY "cdh1_mutation_pct" DESC NULLS LAST
LIMIT 5;