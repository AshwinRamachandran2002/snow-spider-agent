/*  Top 5 breast‑cancer (BRCA) histological types with the highest
    percentage of CDH1‑mutated patients in the PanCancer Atlas          */

WITH brca_tot AS (   -- total BRCA patients per histology
    SELECT
        "histological_type",
        COUNT(DISTINCT "bcr_patient_barcode")     AS "total_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
    GROUP BY "histological_type"
),
brca_mut AS (        -- BRCA patients harbouring a CDH1 mutation per histology
    SELECT
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode")   AS "cdh1_mutated_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"  c
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"                 m
          ON c."bcr_patient_barcode" = m."ParticipantBarcode"
    WHERE c."acronym" = 'BRCA'
      AND m."Hugo_Symbol" = 'CDH1'
    GROUP BY c."histological_type"
)

SELECT
    t."histological_type",
    t."total_patients",
    COALESCE(m."cdh1_mutated_patients",0)                                  AS "cdh1_mutated_patients",
    ROUND(100.0 * COALESCE(m."cdh1_mutated_patients",0) / t."total_patients", 2)
                                                                          AS "cdh1_mutation_pct"
FROM brca_tot t
LEFT JOIN brca_mut m
       ON t."histological_type" = m."histological_type"
WHERE t."total_patients" > 0
ORDER BY "cdh1_mutation_pct" DESC NULLS LAST, t."histological_type"
LIMIT 5;