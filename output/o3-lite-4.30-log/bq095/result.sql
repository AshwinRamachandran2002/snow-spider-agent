SELECT
  COALESCE(m.name, k.prefName)               AS drug_name,
  t.approvedSymbol                           AS target_approved_symbol,
  STRING_AGG(DISTINCT u.element.url, ' | ')  AS clinical_trials
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
JOIN `bigquery-public-data.open_targets_platform.molecule`             AS m
  ON k.drugId = m.id
LEFT JOIN `bigquery-public-data.open_targets_platform.targets`         AS t
  ON k.targetId = t.id
CROSS JOIN UNNEST(k.urls.list) AS u
WHERE k.diseaseId = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND LOWER(k.status) = 'completed'        -- keep only completed trials
GROUP BY
  drug_name,
  target_approved_symbol
ORDER BY
  drug_name;