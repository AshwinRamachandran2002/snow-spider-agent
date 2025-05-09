-- Drugs with completed clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
-- Return the molecule name, target approved symbol, and clinical-trial link(s)
SELECT DISTINCT
  m.name                       AS drug_name,
  k.approvedSymbol             AS target_symbol,
  u.element.url                AS clinical_trial_url
FROM
  `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
JOIN
  `bigquery-public-data.open_targets_platform.molecule`            AS m
ON
  m.id = k.drugId
LEFT JOIN
  UNNEST(k.urls.list) AS u
WHERE
  k.diseaseId = 'EFO_0007416'              -- pancreatic endocrine carcinoma
  AND LOWER(k.status) = 'completed'        -- only completed trials
ORDER BY
  drug_name,
  target_symbol,
  clinical_trial_url;