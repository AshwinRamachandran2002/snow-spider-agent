SELECT c."histological_type",
       ROUND((COUNT(DISTINCT c."bcr_patient_barcode") * 100.0) / t.total_patients, 4) AS "Percentage_of_CDH1_Mutations"
FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    ON c."bcr_patient_barcode" = m."ParticipantBarcode"
JOIN (
    SELECT "histological_type", COUNT(DISTINCT "bcr_patient_barcode") AS total_patients
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
    GROUP BY "histological_type"
) t ON c."histological_type" = t."histological_type"
WHERE c."acronym" = 'BRCA' AND m."Hugo_Symbol" = 'CDH1' AND m."Study" = 'BRCA'
GROUP BY c."histological_type", t.total_patients
ORDER BY "Percentage_of_CDH1_Mutations" DESC NULLS LAST
LIMIT 5;