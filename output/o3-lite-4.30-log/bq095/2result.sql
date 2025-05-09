SELECT
  m.name                           AS drug_name,
  k.approvedSymbol                 AS target_approved_symbol,
  STRING_AGG(DISTINCT u.element.url, '; ') AS clinical_trials
FROM  `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
JOIN  `bigquery-public-data.open_targets_platform.molecule`            AS m
      ON k.drugId = m.id
LEFT JOIN UNNEST(k.urls.list) AS u
WHERE k.diseaseId = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND LOWER(k.status) = 'completed'        -- completed clinical trials
  AND LOWER(u.element.niceName) = 'clinicaltrials'
GROUP BY
  drug_name,
  target_approved_symbol
ORDER BY
  drug_name;