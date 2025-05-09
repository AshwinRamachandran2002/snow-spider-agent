-- Drugs with completed clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
WITH completed_trials AS (
  SELECT
    k.drugId,
    k.targetId,
    url_struct.element.url AS trial_url
  FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
  -- every ClinicalTrials link is stored inside the urls.list array
  CROSS JOIN UNNEST(k.urls.list) AS url_struct
  WHERE k.diseaseId = 'EFO_0007416'
    AND LOWER(k.status) = 'completed'      -- keep only completed trials
)

SELECT
  m.name                         AS drug_name,
  t.approvedSymbol               AS target_symbol,
  ARRAY_AGG(DISTINCT ct.trial_url ORDER BY ct.trial_url) AS trial_urls
FROM completed_trials AS ct
JOIN `bigquery-public-data.open_targets_platform.molecule` AS m
  ON ct.drugId = m.id
JOIN `bigquery-public-data.open_targets_platform.targets`   AS t
  ON ct.targetId = t.id
GROUP BY
  drug_name,
  target_symbol
ORDER BY
  drug_name;