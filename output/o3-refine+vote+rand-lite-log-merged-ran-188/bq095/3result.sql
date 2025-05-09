-- Drugs with completed clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
SELECT
  m.name                                     AS drug_name,
  kd.approvedSymbol                          AS target_symbol,
  STRING_AGG(DISTINCT u.element.url, ' | ')  AS clinical_trial_urls
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS kd
JOIN `bigquery-public-data.open_targets_platform.molecule`             AS m
  ON m.id = kd.drugId
JOIN UNNEST(kd.urls.list) AS u
WHERE kd.diseaseId = 'EFO_0007416'               -- pancreatic endocrine carcinoma
  AND LOWER(kd.status) = 'completed'             -- completed trials only
GROUP BY drug_name, target_symbol
ORDER BY drug_name;