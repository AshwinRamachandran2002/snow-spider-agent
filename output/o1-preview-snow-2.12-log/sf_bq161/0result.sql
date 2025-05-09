SELECT ("both_mutated" - "neither_mutated") AS "net_difference" FROM (
    WITH paad_patients AS (
        SELECT DISTINCT "bcr_patient_barcode" AS "PatientBarcode"
        FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP"
        WHERE "acronym" = 'PAAD'
    ),
    kras_mutations AS (
        SELECT DISTINCT "ParticipantBarcode"
        FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
        WHERE "Study" = 'PAAD' AND "FILTER" = 'PASS' AND "Hugo_Symbol" = 'KRAS'
    ),
    tp53_mutations AS (
        SELECT DISTINCT "ParticipantBarcode"
        FROM "PANCANCER_ATLAS_2"."PANCANCER_ATLAS"."FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
        WHERE "Study" = 'PAAD' AND "FILTER" = 'PASS' AND "Hugo_Symbol" = 'TP53'
    ),
    patient_mutation_status AS (
        SELECT 
            paad."PatientBarcode",
            CASE WHEN kras."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS "KRAS_Mutated",
            CASE WHEN tp53."ParticipantBarcode" IS NOT NULL THEN 1 ELSE 0 END AS "TP53_Mutated"
        FROM paad_patients paad
        LEFT JOIN kras_mutations kras ON paad."PatientBarcode" = kras."ParticipantBarcode"
        LEFT JOIN tp53_mutations tp53 ON paad."PatientBarcode" = tp53."ParticipantBarcode"
    ),
    counts AS (
        SELECT
            SUM(CASE WHEN "KRAS_Mutated" = 1 AND "TP53_Mutated" = 1 THEN 1 ELSE 0 END) AS "both_mutated",
            SUM(CASE WHEN "KRAS_Mutated" = 0 AND "TP53_Mutated" = 0 THEN 1 ELSE 0 END) AS "neither_mutated"
        FROM patient_mutation_status
    )
    SELECT * FROM counts
);