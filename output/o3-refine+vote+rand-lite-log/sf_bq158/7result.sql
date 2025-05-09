WITH brca_patients AS (
    SELECT
        "bcr_patient_barcode"          AS patient_barcode,
        "histological_type"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
),
cdh1_mutated AS (
    -- one record per BRCA patient carrying at least one CDH1 mutation that passed all filters
    SELECT DISTINCT
        "ParticipantBarcode" AS patient_barcode
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND "FILTER" = 'PASS'
)
SELECT
    bp."histological_type"                                           AS "histological_type",
    COUNT(*)                                                         AS "total_patients",
    COUNT(cm.patient_barcode)                                        AS "patients_with_CDH1_mutation",
    ROUND(100.0 * COUNT(cm.patient_barcode) / COUNT(*), 4)           AS "mutation_percentage"
FROM brca_patients bp
LEFT JOIN cdh1_mutated cm
       ON bp.patient_barcode = cm.patient_barcode
GROUP BY bp."histological_type"
ORDER BY "mutation_percentage" DESC NULLS LAST,
         "patients_with_CDH1_mutation" DESC,
         "histological_type"
FETCH FIRST 5 ROWS;