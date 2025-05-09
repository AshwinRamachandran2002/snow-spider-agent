-- List drugs (with molecular details) that have completed clinical trials
-- for pancreatic endocrine carcinoma (EFO_0007416), showing drug name,
-- target approved symbol, and ClinicalTrials links.
WITH trial_details AS (
  SELECT
    k.`drugId`,
    -- Prefer the molecule table's name; if missing fall back to knownDrugsAggregated.prefName
    COALESCE(m.`name`, k.`prefName`)            AS drug_name,
    k.`approvedSymbol`                          AS target_symbol,
    u.element.`url`                             AS clinical_trial_url
  FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` k
  JOIN `bigquery-public-data.open_targets_platform.molecule` m
    ON m.`id` = k.`drugId`
  CROSS JOIN UNNEST(k.`urls`.list) AS u
  WHERE k.`diseaseId` = 'EFO_0007416'                 -- pancreatic endocrine carcinoma
    AND LOWER(k.`status`) = 'completed'               -- only completed trials
    AND LOWER(u.element.`niceName`) = 'clinicaltrials' -- keep ClinicalTrials links
)
SELECT
  drug_name,
  target_symbol,
  ARRAY_AGG(DISTINCT clinical_trial_url ORDER BY clinical_trial_url) AS clinical_trial_urls
FROM trial_details
GROUP BY drug_name, target_symbol
ORDER BY drug_name;