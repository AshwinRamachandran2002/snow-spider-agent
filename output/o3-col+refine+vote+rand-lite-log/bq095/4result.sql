-- Drugs with completed trials for pancreatic endocrine carcinoma (EFO_0007416)
-- together with their target symbols and ClinicalTrials links
SELECT DISTINCT
  m.name                      AS drug_name,
  t.approvedSymbol            AS target_symbol,
  url.element.url             AS clinical_trial_url
FROM  `bigquery-public-data.open_targets_platform.knownDrugsAggregated`  AS k
JOIN  `bigquery-public-data.open_targets_platform.molecule`              AS m
      ON k.drugId  = m.id
JOIN  `bigquery-public-data.open_targets_platform.targets`               AS t
      ON k.targetId = t.id
JOIN  UNNEST(IFNULL(k.urls.list, [])) AS url
WHERE k.diseaseId = 'EFO_0007416'                 -- pancreatic endocrine carcinoma
  AND LOWER(k.status) = 'completed'               -- only completed trials
  AND url.element.niceName = 'ClinicalTrials'     -- keep ClinicalTrials sources
ORDER BY drug_name, target_symbol, clinical_trial_url;