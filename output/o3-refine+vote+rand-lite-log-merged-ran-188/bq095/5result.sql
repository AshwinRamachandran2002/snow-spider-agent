-- Drugs with COMPLETED clinical trials for pancreatic endocrine carcinoma (EFO_0007416),
-- together with their target gene symbols and the associated ClinicalTrials links.
SELECT DISTINCT
  m.name                AS drug_name,
  t.approvedSymbol      AS target_symbol,
  url.element.url       AS clinical_trial_url
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
JOIN `bigquery-public-data.open_targets_platform.molecule`             AS m
  ON m.id = k.drugId
JOIN `bigquery-public-data.open_targets_platform.targets`              AS t
  ON t.id = k.targetId
JOIN UNNEST(k.urls.list) AS url
WHERE k.diseaseId = 'EFO_0007416'      -- pancreatic endocrine carcinoma
  AND k.status    = 'Completed'        -- only completed trials
ORDER BY
  drug_name,
  target_symbol,
  clinical_trial_url;