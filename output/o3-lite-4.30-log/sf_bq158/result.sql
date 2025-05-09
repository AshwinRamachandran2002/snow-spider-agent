WITH total AS (
    SELECT
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode") AS total_patients
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'BRCA'
    GROUP BY c."histological_type"
),
mut AS (
    SELECT
        c."histological_type",
        COUNT(DISTINCT c."bcr_patient_barcode") AS cdh1_mut_patients
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
      ON c."bcr_patient_barcode" = m."ParticipantBarcode"
    WHERE c."acronym" = 'BRCA'
      AND m."Study" = 'BRCA'
      AND m."Hugo_Symbol" = 'CDH1'
    GROUP BY c."histological_type"
)
SELECT
    t."histological_type",
    ROUND(
        100.0 * COALESCE(m.cdh1_mut_patients, 0)
        / NULLIF(t.total_patients, 0), 4
    ) AS cdh1_mutation_percentage
FROM total t
LEFT JOIN mut m
  ON t."histological_type" = m."histological_type"
ORDER BY cdh1_mutation_percentage DESC NULLS LAST, t."histological_type"
LIMIT 5;