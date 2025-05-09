-- Net difference =  (# PAAD patients with BOTH KRAS & TP53 mutations)
--                  – (# PAAD patients with NEITHER KRAS NOR TP53 mutations)
WITH
/* --------------------------------------------------------------------------
   1.  Complete PAAD patient roster (clinical follow-up table)
---------------------------------------------------------------------------*/
all_paad AS (
  SELECT DISTINCT
         `bcr_patient_barcode` AS ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE  `acronym` = 'PAAD'
),

/* --------------------------------------------------------------------------
   2.  Patients carrying a filtered KRAS mutation
---------------------------------------------------------------------------*/
kras AS (
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
    AND  Hugo_Symbol = 'KRAS'
),

/* --------------------------------------------------------------------------
   3.  Patients carrying a filtered TP53 mutation
---------------------------------------------------------------------------*/
tp53 AS (
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
    AND  Hugo_Symbol = 'TP53'
),

/* --------------------------------------------------------------------------
   4.  Patients with BOTH KRAS and TP53 mutations
---------------------------------------------------------------------------*/
both_mut AS (
  SELECT ParticipantBarcode
  FROM   kras
  JOIN   tp53 USING (ParticipantBarcode)
),

/* --------------------------------------------------------------------------
   5.  Patients with ANY mutation in KRAS or TP53
---------------------------------------------------------------------------*/
mut_any AS (
  SELECT DISTINCT
         ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study = 'PAAD'
    AND  Hugo_Symbol IN ('KRAS', 'TP53')
),

/* --------------------------------------------------------------------------
   6.  Patients with NEITHER KRAS NOR TP53 mutation
---------------------------------------------------------------------------*/
neither_mut AS (
  SELECT ParticipantBarcode
  FROM   all_paad
  WHERE  ParticipantBarcode NOT IN (SELECT ParticipantBarcode FROM mut_any)
)

/* --------------------------------------------------------------------------
   7.  Net difference
---------------------------------------------------------------------------*/
SELECT
  (SELECT COUNT(DISTINCT ParticipantBarcode) FROM both_mut) -
  (SELECT COUNT(DISTINCT ParticipantBarcode) FROM neither_mut) AS net_difference;