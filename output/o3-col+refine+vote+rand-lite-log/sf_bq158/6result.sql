/*  Top-5 BRCA histological types with the highest percentage of CDH1-mutated patients */
WITH total AS (   -- all BRCA patients per histology
    SELECT
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode") AS "total_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
    WHERE c."acronym" = 'BRCA'
      AND c."histological_type" IS NOT NULL
      AND TRIM(c."histological_type") <> ''
    GROUP BY c."histological_type"
),
mutant AS (       -- BRCA patients whose tumours carry a CDH1 mutation
    SELECT
        c."histological_type",
        COUNT(DISTINCT m."ParticipantBarcode") AS "cdh1_mutant_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE      m
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED c
      ON m."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE m."Study"         = 'BRCA'
      AND m."Hugo_Symbol"   = 'CDH1'
      AND c."histological_type" IS NOT NULL
      AND TRIM(c."histological_type") <> ''
    GROUP BY c."histological_type"
)
SELECT
    t."histological_type",
    m."cdh1_mutant_patients",
    t."total_patients",
    (m."cdh1_mutant_patients" * 100.0) / t."total_patients"  AS "cdh1_mutation_percentage"
FROM total t
JOIN mutant m
  ON m."histological_type" = t."histological_type"
ORDER BY "cdh1_mutation_percentage" DESC NULLS LAST
LIMIT 5;