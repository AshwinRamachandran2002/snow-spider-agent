-- Net difference =
--   (# PAAD patients mutated in BOTH KRAS AND TP53)
-- – (# PAAD patients mutated in NEITHER KRAS NOR TP53)

WITH
-- All PAAD patients present in the clinical follow-up file
all_paad AS (
  SELECT DISTINCT `bcr_patient_barcode` AS patient
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE `acronym` = 'PAAD'
),

-- Patients whose tumours have a KRAS mutation (quality-filtered MC3 data)
kras AS (
  SELECT DISTINCT `ParticipantBarcode` AS patient
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study` = 'PAAD'
    AND `Hugo_Symbol` = 'KRAS'
),

-- Patients whose tumours have a TP53 mutation
tp53 AS (
  SELECT DISTINCT `ParticipantBarcode` AS patient
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE `Study` = 'PAAD'
    AND `Hugo_Symbol` = 'TP53'
),

-- Patients mutated in BOTH KRAS AND TP53
both_mutated AS (
  SELECT k.patient
  FROM kras k
  INNER JOIN tp53 t USING (patient)
),

-- Patients mutated in EITHER gene
mut_any AS (
  SELECT patient FROM kras
  UNION DISTINCT
  SELECT patient FROM tp53
),

-- PAAD patients mutated in NEITHER gene
neither_mutated AS (
  SELECT patient
  FROM all_paad
  WHERE patient NOT IN (SELECT patient FROM mut_any)
)

SELECT
  (SELECT COUNT(*) FROM both_mutated)   AS n_both_mutated,
  (SELECT COUNT(*) FROM neither_mutated) AS n_neither_mutated,
  (SELECT COUNT(*) FROM both_mutated) -
  (SELECT COUNT(*) FROM neither_mutated) AS net_difference;