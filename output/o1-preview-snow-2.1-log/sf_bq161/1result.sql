WITH
PAAD_Patients AS (
    SELECT DISTINCT "bcr_patient_barcode" AS "Patient"
    FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
    WHERE "acronym" = 'PAAD'
),
KRAS_Mutations AS (
    SELECT DISTINCT "ParticipantBarcode" AS "Patient"
    FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Hugo_Symbol" = 'KRAS' AND "FILTER" = 'PASS' AND "Study" = 'PAAD'
),
TP53_Mutations AS (
    SELECT DISTINCT "ParticipantBarcode" AS "Patient"
    FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Hugo_Symbol" = 'TP53' AND "FILTER" = 'PASS' AND "Study" = 'PAAD'
),
Patient_Mutations AS (
    SELECT
        P."Patient",
        CASE WHEN K."Patient" IS NOT NULL THEN 1 ELSE 0 END AS "KRAS_mut",
        CASE WHEN T."Patient" IS NOT NULL THEN 1 ELSE 0 END AS "TP53_mut"
    FROM
        PAAD_Patients P
        LEFT JOIN KRAS_Mutations K ON P."Patient" = K."Patient"
        LEFT JOIN TP53_Mutations T ON P."Patient" = T."Patient"
)
SELECT
    (SUM(CASE WHEN "KRAS_mut" = 1 AND "TP53_mut" = 1 THEN 1 ELSE 0 END) -
     SUM(CASE WHEN "KRAS_mut" = 0 AND "TP53_mut" = 0 THEN 1 ELSE 0 END)) AS "net_difference"
FROM Patient_Mutations;