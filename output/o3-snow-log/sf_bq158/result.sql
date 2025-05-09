WITH brca_clin AS (
    SELECT 
        "bcr_patient_barcode"          AS "patient",
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
), brca_patients AS (
    SELECT DISTINCT 
        "patient",
        "histological_type"
    FROM brca_clin
), cdh1_mut AS (
    SELECT DISTINCT 
        m."ParticipantBarcode" AS "patient"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE" m
    JOIN brca_patients bp
      ON bp."patient" = m."ParticipantBarcode"
    WHERE m."Hugo_Symbol" = 'CDH1'
      AND m."FILTER" = 'PASS'
)
SELECT 
    bp."histological_type",
    COUNT(DISTINCT bp."patient")                                              AS "total_patients",
    COUNT(DISTINCT cm."patient")                                              AS "patients_with_CDH1_mut",
    ROUND(100.0 * COUNT(DISTINCT cm."patient") / COUNT(DISTINCT bp."patient"), 4) 
                                                                              AS "percent_CDH1_mut"
FROM brca_patients bp
LEFT JOIN cdh1_mut cm
  ON cm."patient" = bp."patient"
GROUP BY bp."histological_type"
ORDER BY "percent_CDH1_mut" DESC NULLS LAST
LIMIT 5;