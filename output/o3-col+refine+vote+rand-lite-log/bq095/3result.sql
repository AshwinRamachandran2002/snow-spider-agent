-- Drugs with completed clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
SELECT
  k.drugId,
  COALESCE(m.name, k.prefName) AS drug_name,
  k.approvedSymbol            AS target_symbol,
  ARRAY_AGG(DISTINCT url_item.element.url) AS clinical_trial_urls
FROM  `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS k
LEFT JOIN `bigquery-public-data.open_targets_platform.molecule`          AS m
       ON m.id = k.drugId
LEFT JOIN UNNEST(k.urls.list) AS url_item
WHERE k.diseaseId = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND LOWER(k.status) = 'completed'        -- trials that have finished
GROUP BY k.drugId, drug_name, target_symbol
ORDER BY drug_name;