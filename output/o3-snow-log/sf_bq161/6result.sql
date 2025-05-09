WITH
/* all PAAD patients with clinical records */
paad_patients AS (
    SELECT DISTINCT
           "bcr_patient_barcode" AS "ParticipantBarcode"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP
    WHERE "acronym" = 'PAAD'
),
/* PAAD patients whose tumour samples carry a PASS-filtered KRAS mutation */
kras_mut AS (
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'PAAD'
      AND "FILTER" = 'PASS'
      AND "Hugo_Symbol" = 'KRAS'
),
/* PAAD patients whose tumour samples carry a PASS-filtered TP53 mutation */
tp53_mut AS (
    SELECT DISTINCT
           "ParticipantBarcode"
    FROM PANCANCER_ATLAS_2.PANCANCER_ATLAS.FILTERED_MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE "Study" = 'PAAD'
      AND "FILTER" = 'PASS'
      AND "Hugo_Symbol" = 'TP53'
),
/* patients mutated in BOTH genes */
both_mut AS (
    SELECT p."ParticipantBarcode"
    FROM paad_patients p
    INNER JOIN kras_mut k  USING ("ParticipantBarcode")
    INNER JOIN tp53_mut t USING ("ParticipantBarcode")
),
/* patients mutated in NEITHER gene */
no_kras_tp53_mut AS (
    SELECT p."ParticipantBarcode"
    FROM paad_patients p
    LEFT JOIN kras_mut k  USING ("ParticipantBarcode")
    LEFT JOIN tp53_mut t USING ("ParticipantBarcode")
    WHERE k."ParticipantBarcode" IS NULL
      AND t."ParticipantBarcode" IS NULL
)
/* final counts and net difference */
SELECT
    (SELECT COUNT(*) FROM both_mut)                     AS "Patients_with_KRAS_and_TP53_Mutations",
    (SELECT COUNT(*) FROM no_kras_tp53_mut)             AS "Patients_without_KRAS_or_TP53_Mutations",
    (SELECT COUNT(*) FROM both_mut) -
    (SELECT COUNT(*) FROM no_kras_tp53_mut)             AS "Net_Difference";