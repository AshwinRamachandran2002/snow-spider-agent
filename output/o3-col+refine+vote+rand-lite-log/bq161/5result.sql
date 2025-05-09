/* Net difference between PAAD patients with BOTH KRAS & TP53 mutations 
   and those with NEITHER mutation (TCGA – filtered datasets) */

WITH clinical_paad AS (          -- All PAAD cases with follow-up data
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),

kras_mut AS (                    -- PAAD patients harbouring a KRAS mutation
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD' AND Hugo_Symbol = 'KRAS'
),

tp53_mut AS (                    -- PAAD patients harbouring a TP53 mutation
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD' AND Hugo_Symbol = 'TP53'
),

both_mut AS (                    -- Patients with mutations in BOTH genes
  SELECT k.ParticipantBarcode
  FROM kras_mut k
  INNER JOIN tp53_mut t USING (ParticipantBarcode)
),

any_mut AS (                     -- Patients with EITHER mutation
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND Hugo_Symbol IN ('KRAS', 'TP53')
),

neither_mut AS (                 -- Clinical PAAD cases with NEITHER mutation
  SELECT c.ParticipantBarcode
  FROM clinical_paad c
  WHERE c.ParticipantBarcode NOT IN (SELECT ParticipantBarcode FROM any_mut)
)

SELECT
  (SELECT COUNT(*) FROM both_mut)    AS both_mut_ct,
  (SELECT COUNT(*) FROM neither_mut) AS neither_mut_ct,
  (SELECT COUNT(*) FROM both_mut) -
  (SELECT COUNT(*) FROM neither_mut) AS net_difference;