-- Net difference between PAAD patients with BOTH KRAS & TP53 mutations
-- (quality‑filtered) and those with NEITHER mutation
WITH
/* -------------------------------------------
   All pancreatic adenocarcinoma (PAAD) cases
--------------------------------------------*/
paad_patients AS (
  SELECT DISTINCT
    bcr_patient_barcode AS ParticipantBarcode
  FROM
    `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE
    acronym = 'PAAD'
),

/* -------------------------------------------
   PAAD patients whose tumours carry a quality‑passed KRAS mutation
--------------------------------------------*/
kras_mut AS (
  SELECT DISTINCT
    ParticipantBarcode
  FROM
    `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE
    Study = 'PAAD'
    AND Hugo_Symbol = 'KRAS'
    AND FILTER = 'PASS'                       -- only high‑quality calls
),

/* -------------------------------------------
   PAAD patients whose tumours carry a quality‑passed TP53 mutation
--------------------------------------------*/
tp53_mut AS (
  SELECT DISTINCT
    ParticipantBarcode
  FROM
    `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE
    Study = 'PAAD'
    AND Hugo_Symbol = 'TP53'
    AND FILTER = 'PASS'
),

/* -------------------------------------------
   Patients with BOTH KRAS AND TP53 mutations
--------------------------------------------*/
both_mut AS (
  SELECT ParticipantBarcode
  FROM kras_mut
  INTERSECT DISTINCT
  SELECT ParticipantBarcode
  FROM tp53_mut
),

/* -------------------------------------------
   Patients with EITHER mutation (used to find those with none)
--------------------------------------------*/
either_mut AS (
  SELECT ParticipantBarcode FROM kras_mut
  UNION DISTINCT
  SELECT ParticipantBarcode FROM tp53_mut
),

/* -------------------------------------------
   PAAD patients with NEITHER mutation
--------------------------------------------*/
neither_mut AS (
  SELECT ParticipantBarcode
  FROM paad_patients
  WHERE ParticipantBarcode NOT IN (SELECT ParticipantBarcode FROM either_mut)
)

/* -------------------------------------------
   Return counts and net difference
--------------------------------------------*/
SELECT
  (SELECT COUNT(*) FROM both_mut)   AS patients_with_both_mutations,
  (SELECT COUNT(*) FROM neither_mut) AS patients_with_neither_mutation,
  (SELECT COUNT(*) FROM both_mut) -
  (SELECT COUNT(*) FROM neither_mut) AS net_difference;