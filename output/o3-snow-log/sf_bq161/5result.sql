WITH clin_paad AS (  -- PAAD patients with clinical follow-up data
    SELECT DISTINCT "bcr_patient_barcode" AS patient_barcode
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),
kras_mut AS (         -- PAAD patients with a PASS KRAS mutation
    SELECT DISTINCT "ParticipantBarcode" AS patient_barcode
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"      = 'PAAD'
      AND "Hugo_Symbol" = 'KRAS'
      AND "FILTER"      = 'PASS'
),
tp53_mut AS (         -- PAAD patients with a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode" AS patient_barcode
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study"      = 'PAAD'
      AND "Hugo_Symbol" = 'TP53'
      AND "FILTER"      = 'PASS'
),
both_mut AS (         -- patients mutated in BOTH KRAS and TP53
    SELECT patient_barcode
    FROM clin_paad
    WHERE patient_barcode IN (SELECT patient_barcode FROM kras_mut)
      AND patient_barcode IN (SELECT patient_barcode FROM tp53_mut)
),
none_mut AS (         -- patients mutated in NEITHER KRAS nor TP53
    SELECT patient_barcode
    FROM clin_paad
    WHERE patient_barcode NOT IN (SELECT patient_barcode FROM kras_mut)
      AND patient_barcode NOT IN (SELECT patient_barcode FROM tp53_mut)
)
SELECT
    (SELECT COUNT(*) FROM both_mut) AS "num_both_kras_tp53_mut",
    (SELECT COUNT(*) FROM none_mut) AS "num_no_kras_tp53_mut",
    (SELECT COUNT(*) FROM both_mut) - (SELECT COUNT(*) FROM none_mut) AS "net_difference";