-- Net difference between PAAD patients with BOTH KRAS & TP53 mutations
-- and those with NEITHER mutation
WITH
-- PAAD patients harboring a KRAS mutation
kras AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND UPPER(Hugo_Symbol) = 'KRAS'
),

-- PAAD patients harboring a TP53 mutation
tp53 AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.Filtered_MC3_MAF_V5_one_per_tumor_sample`
  WHERE Study = 'PAAD'
    AND UPPER(Hugo_Symbol) = 'TP53'
),

-- Patients with BOTH KRAS AND TP53 mutations
both_mut AS (
  SELECT ParticipantBarcode
  FROM kras
  INNER JOIN tp53 USING (ParticipantBarcode)
),

-- All PAAD patients represented in the clinical follow-up resource
all_paad AS (
  SELECT DISTINCT ParticipantBarcode
  FROM `isb-cgc-bq.pancancer_atlas.TCGA_CDR`
  WHERE Study = 'PAAD'
),

-- Patients with NEITHER KRAS NOR TP53 mutations
none_mut AS (
  SELECT ParticipantBarcode
  FROM all_paad
  WHERE ParticipantBarcode NOT IN (
        SELECT ParticipantBarcode FROM kras
        UNION DISTINCT
        SELECT ParticipantBarcode FROM tp53)
)

-- Final net difference (BOTH − NEITHER)
SELECT
  (SELECT COUNT(*) FROM both_mut)
  -
  (SELECT COUNT(*) FROM none_mut) AS net_difference;