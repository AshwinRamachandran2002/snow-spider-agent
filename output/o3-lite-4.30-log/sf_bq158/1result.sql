WITH total AS (
    SELECT
        "histological_type",
        COUNT(DISTINCT "bcr_patient_barcode") AS total_patients
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
    GROUP BY "histological_type"
),
mutated AS (
    SELECT
        c."histological_type",
        COUNT(DISTINCT m."ParticipantBarcode") AS mutated_patients
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
      ON m."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE m."Study" = 'BRCA'
      AND m."Hugo_Symbol" = 'CDH1'
      AND c."acronym" = 'BRCA'
    GROUP BY c."histological_type"
)
SELECT
    t."histological_type",
    ROUND(COALESCE(m.mutated_patients,0) * 100.0 / t.total_patients, 4) AS cdh1_mutation_percentage
FROM total t
LEFT JOIN mutated m
  ON t."histological_type" = m."histological_type"
ORDER BY cdh1_mutation_percentage DESC NULLS LAST, t."histological_type"
LIMIT 5;