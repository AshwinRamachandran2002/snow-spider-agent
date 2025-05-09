WITH brca_clin AS (
    SELECT DISTINCT
        "bcr_patient_barcode" AS patient_barcode,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "bcr_patient_barcode" IS NOT NULL
), 
cdh1_mut AS (
    SELECT DISTINCT 
        "ParticipantBarcode" AS patient_barcode
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
)
SELECT
    bc."histological_type",
    COUNT(*)                                                     AS total_patients,
    SUM(CASE WHEN cm.patient_barcode IS NOT NULL THEN 1 END)     AS mutated_patients,
    ROUND(SUM(CASE WHEN cm.patient_barcode IS NOT NULL THEN 1 END) 
          * 100.0 / COUNT(*), 4)                                 AS mutation_percentage
FROM brca_clin bc
LEFT JOIN cdh1_mut cm
       ON bc.patient_barcode = cm.patient_barcode
GROUP BY bc."histological_type"
ORDER BY mutation_percentage DESC NULLS LAST
LIMIT 5;