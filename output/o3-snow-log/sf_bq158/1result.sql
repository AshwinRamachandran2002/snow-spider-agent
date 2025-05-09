WITH brca_clinical AS (
    SELECT
        "bcr_patient_barcode"  AS patient_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE
        "acronym" = 'BRCA'
        AND "histological_type" IS NOT NULL
),
cdh1_mutated_patients AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS patient_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE
        "Study" = 'BRCA'
        AND "Hugo_Symbol" = 'CDH1'
)
SELECT
    c."histological_type",
    COUNT(DISTINCT CASE WHEN m.patient_id IS NOT NULL THEN c.patient_id END) AS "mutated_patients",
    COUNT(DISTINCT c.patient_id)                                            AS "total_patients",
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN m.patient_id IS NOT NULL THEN c.patient_id END)
        / COUNT(DISTINCT c.patient_id)
    , 4)                                                                    AS "mutation_percentage"
FROM brca_clinical c
LEFT JOIN cdh1_mutated_patients m
       ON c.patient_id = m.patient_id
GROUP BY c."histological_type"
ORDER BY "mutation_percentage" DESC NULLS LAST
LIMIT 5;