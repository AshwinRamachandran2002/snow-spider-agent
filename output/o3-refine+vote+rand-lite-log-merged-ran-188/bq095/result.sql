-- Drugs with completed clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
SELECT DISTINCT
  m.name            AS drug_name,
  k.approvedSymbol  AS target_symbol,
  url.element.url   AS clinical_trial_url
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
JOIN `bigquery-public-data.open_targets_platform.molecule`            AS m
  ON k.drugId = m.id
CROSS JOIN UNNEST(k.urls.list) AS url
WHERE k.diseaseId = 'EFO_0007416'      -- pancreatic endocrine carcinoma
  AND LOWER(k.status) = 'completed'    -- only completed trials
ORDER BY
  drug_name,
  target_symbol,
  clinical_trial_url;