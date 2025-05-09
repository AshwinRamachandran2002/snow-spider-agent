WITH clinical_braca AS (
    SELECT DISTINCT
        "bcr_patient_barcode"  AS patient_id,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
), 
mutation_braca AS (
    SELECT DISTINCT
        "ParticipantBarcode" AS patient_id
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
)
SELECT
    c."histological_type"                                 AS "Histological_Type",
    COUNT(DISTINCT c.patient_id)                          AS "Total_Patients",
    COUNT(DISTINCT CASE WHEN m.patient_id IS NOT NULL 
                        THEN c.patient_id END)            AS "Mutated_Patients",
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN m.patient_id IS NOT NULL 
                                      THEN c.patient_id END)
          / COUNT(DISTINCT c.patient_id), 2)              AS "CDH1_Mutation_Percentage"
FROM clinical_braca c
LEFT JOIN mutation_braca m
       ON c.patient_id = m.patient_id
GROUP BY c."histological_type"
ORDER BY "CDH1_Mutation_Percentage" DESC NULLS LAST
LIMIT 5;