WITH clinical AS (
    SELECT DISTINCT
           "bcr_patient_barcode"      AS patient_id,
           "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
cdh1_mutated AS (
    SELECT DISTINCT
           "ParticipantBarcode"       AS patient_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"        = 'BRCA'
      AND "Hugo_Symbol"  = 'CDH1'
      AND "FILTER"       = 'PASS'
)
SELECT
       c."histological_type"                                         AS "Histological_Type",
       COUNT(*)                                                      AS "Total_Patients",
       COUNT(m.patient_id)                                           AS "Patients_With_CDH1_Mutation",
       ROUND(100.0 * COUNT(m.patient_id) / COUNT(*), 4)              AS "Mutation_Percentage"
FROM clinical c
LEFT JOIN cdh1_mutated m
       ON c.patient_id = m.patient_id
GROUP BY
       c."histological_type"
ORDER BY
       "Mutation_Percentage" DESC NULLS LAST
LIMIT 5;