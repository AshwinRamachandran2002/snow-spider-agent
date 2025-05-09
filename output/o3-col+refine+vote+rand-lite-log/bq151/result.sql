/* -----------------------------------------------------------
   Chi-square test for association of KRAS and TP53 mutations
   in TCGA pancreatic adenocarcinoma (PAAD) patients
   ----------------------------------------------------------- */
WITH clinical AS (      -- PAAD cases with usable clinical follow-up
  SELECT DISTINCT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE  Study = 'PAAD'
    AND  Redaction IS NULL
),
kras AS (               -- high–quality KRAS mutations
  SELECT DISTINCT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study        = 'PAAD'
    AND  Hugo_Symbol  = 'KRAS'
    AND  FILTER       = 'PASS'
),
tp53 AS (               -- high–quality TP53 mutations
  SELECT DISTINCT ParticipantBarcode
  FROM   `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE  Study        = 'PAAD'
    AND  Hugo_Symbol  = 'TP53'
    AND  FILTER       = 'PASS'
),
status AS (             -- mutation status for every clinical patient
  SELECT
    c.ParticipantBarcode,
    IF(k.ParticipantBarcode IS NULL,0,1) AS has_KRAS,
    IF(t.ParticipantBarcode IS NULL,0,1) AS has_TP53
  FROM clinical c
  LEFT JOIN kras k USING (ParticipantBarcode)
  LEFT JOIN tp53 t USING (ParticipantBarcode)
),
counts AS (             -- 2×2 contingency table
  SELECT
    SUM(CASE WHEN has_KRAS=1 AND has_TP53=1 THEN 1 END) AS both_mut,
    SUM(CASE WHEN has_KRAS=1 AND has_TP53=0 THEN 1 END) AS KRAS_only,
    SUM(CASE WHEN has_KRAS=0 AND has_TP53=1 THEN 1 END) AS TP53_only,
    SUM(CASE WHEN has_KRAS=0 AND has_TP53=0 THEN 1 END) AS none
  FROM status
),
stats AS (              -- expected counts & χ²
  SELECT
    both_mut,
    KRAS_only,
    TP53_only,
    none,
    (both_mut+KRAS_only+TP53_only+none)              AS total,
    (both_mut+KRAS_only)                            AS KRAS_tot,
    (both_mut+TP53_only)                            AS TP53_tot
  FROM counts
)
SELECT
  both_mut,
  KRAS_only,
  TP53_only,
  none,
  total,
  -- expected frequencies under independence
  (KRAS_tot * TP53_tot) / total                        AS exp_both,
  (KRAS_tot * (total - TP53_tot)) / total              AS exp_KRAS_only,
  ((total - KRAS_tot) * TP53_tot) / total              AS exp_TP53_only,
  ((total - KRAS_tot) * (total - TP53_tot)) / total    AS exp_none,
  -- Pearson chi-square statistic (df = 1)
  (
    POW(both_mut  - (KRAS_tot * TP53_tot)/total, 2) / ((KRAS_tot * TP53_tot)/total) +
    POW(KRAS_only - (KRAS_tot * (total-TP53_tot))/total, 2) / ((KRAS_tot * (total-TP53_tot))/total) +
    POW(TP53_only - ((total-KRAS_tot) * TP53_tot)/total, 2) / (((total-KRAS_tot) * TP53_tot)/total) +
    POW(none      - ((total-KRAS_tot)*(total-TP53_tot))/total, 2) / (((total-KRAS_tot)*(total-TP53_tot))/total)
  ) AS chi_squared
FROM stats;