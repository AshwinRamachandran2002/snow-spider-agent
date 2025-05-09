WITH total_patients AS (
    SELECT c."histological_type", COUNT(DISTINCT c."bcr_patient_barcode")::FLOAT AS "total_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    WHERE c."acronym" = 'BRCA'
    GROUP BY c."histological_type"
),
mutation_patients AS (
    SELECT c."histological_type", COUNT(DISTINCT c."bcr_patient_barcode")::FLOAT AS "mutation_patients"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
        ON c."bcr_patient_barcode" = m."ParticipantBarcode"
    WHERE c."acronym" = 'BRCA' AND m."Hugo_Symbol" = 'CDH1'
    GROUP BY c."histological_type"
)
SELECT 
    t."histological_type" AS "Histological_Type",
    ROUND((COALESCE(m."mutation_patients", 0) / t."total_patients") * 100.0, 4) AS "Percentage_of_CDH1_Mutations"
FROM total_patients t
LEFT JOIN mutation_patients m
    ON t."histological_type" = m."histological_type"
ORDER BY "Percentage_of_CDH1_Mutations" DESC NULLS LAST
LIMIT 5;