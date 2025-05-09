WITH total AS (
    SELECT
        "bcr_patient_barcode"        AS patient,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
mutated AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS patient
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER"      = 'PASS'
)
SELECT
    t."histological_type",
    COUNT(CASE WHEN m.patient IS NOT NULL THEN 1 END) AS mutated_patients,
    COUNT(*)                                          AS total_patients,
    ROUND(100.0 * COUNT(CASE WHEN m.patient IS NOT NULL THEN 1 END) 
          / COUNT(*), 4)                              AS mutation_percentage
FROM total t
LEFT JOIN mutated m
       ON t.patient = m.patient
GROUP BY t."histological_type"
ORDER BY mutation_percentage DESC NULLS LAST
LIMIT 5;