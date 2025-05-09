SELECT
  k.prefName AS drug_name,
  k.approvedSymbol AS target_approved_symbol,
  ARRAY_AGG(DISTINCT url.element.url ORDER BY url.element.url) AS clinical_trials
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
CROSS JOIN UNNEST(k.urls.list) AS url
WHERE k.diseaseId = 'EFO_0007416'   -- pancreatic endocrine carcinoma
  AND k.status = 'Completed'        -- only completed clinical trials
GROUP BY
  drug_name,
  target_approved_symbol
ORDER BY
  drug_name;