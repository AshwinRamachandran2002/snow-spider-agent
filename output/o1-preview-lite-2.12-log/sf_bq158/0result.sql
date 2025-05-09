SELECT c."histological_type",
       ROUND(COUNT(DISTINCT m."ParticipantBarcode") * 100.0 / COUNT(DISTINCT c."bcr_patient_barcode"), 4) AS "Percentage_of_CDH1_Mutations"
FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
LEFT JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
  ON c."bcr_patient_barcode" = m."ParticipantBarcode" AND m."Hugo_Symbol" = 'CDH1'
WHERE c."acronym" = 'BRCA' AND c."histological_type" IS NOT NULL
GROUP BY c."histological_type"
ORDER BY "Percentage_of_CDH1_Mutations" DESC NULLS LAST, c."histological_type"
LIMIT 5;