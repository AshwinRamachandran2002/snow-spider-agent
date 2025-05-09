WITH clinical_pa AS (
  -- PAAD patients with clinical / follow‑up information
  SELECT DISTINCT
    UPPER(`bcr_patient_barcode`) AS patient_barcode
  FROM
    `isb-cgc-bq.pancancer_atlas.Filtered_clinical_PANCAN_patient_with_followup`
  WHERE
    UPPER(acronym) = 'PAAD'
),
patient_mutations AS (
  -- Per–patient mutation flags for KRAS and TP53 (high‑quality, PAAD only)
  SELECT
    UPPER(ParticipantBarcode)                    AS patient_barcode,
    MAX(CASE WHEN UPPER(Hugo_Symbol) = 'KRAS'  THEN 1 ELSE 0 END) AS has_kras_mut,
    MAX(CASE WHEN UPPER(Hugo_Symbol) = 'TP53'  THEN 1 ELSE 0 END) AS has_tp53_mut
  FROM
    `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE
    UPPER(Study) = 'PAAD'           -- ensure pancreatic adenocarcinoma
  GROUP BY
    patient_barcode
),
combined AS (
  -- Join clinical cohort with mutation data; patients lacking a record get 0/0 flags
  SELECT
    c.patient_barcode,
    IFNULL(m.has_kras_mut, 0)  AS has_kras_mut,
    IFNULL(m.has_tp53_mut, 0)  AS has_tp53_mut
  FROM
    clinical_pa AS c
  LEFT JOIN
    patient_mutations AS m
  USING (patient_barcode)
),
tally AS (
  SELECT
    SUM(CASE WHEN has_kras_mut = 1 AND has_tp53_mut = 1 THEN 1 ELSE 0 END) AS n_both,
    SUM(CASE WHEN has_kras_mut = 0 AND has_tp53_mut = 0 THEN 1 ELSE 0 END) AS n_neither
  FROM
    combined
)
-- Net difference = (# with both mutations) – (# with neither mutation)
SELECT
  n_both - n_neither AS net_difference_between_groups
FROM
  tally;