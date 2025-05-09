WITH brca_patients AS (
    SELECT DISTINCT
        "bcr_patient_barcode"      AS patient_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
cdh1_mutated_patients AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS patient_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
)
SELECT
    bp."histological_type",
    COUNT(DISTINCT CASE WHEN cmp.patient_id IS NOT NULL THEN bp.patient_id END) AS mutated_patients,
    COUNT(DISTINCT bp.patient_id)                                               AS total_patients,
    ROUND(
        COUNT(DISTINCT CASE WHEN cmp.patient_id IS NOT NULL THEN bp.patient_id END)
        * 100.0
        / COUNT(DISTINCT bp.patient_id)
    , 4) AS mutation_percentage
FROM brca_patients bp
LEFT JOIN cdh1_mutated_patients cmp
       ON bp.patient_id = cmp.patient_id
GROUP BY
    bp."histological_type"
ORDER BY
    mutation_percentage DESC NULLS LAST
LIMIT 5;