SELECT DISTINCT
  COALESCE(mol.name, kd.prefName) AS drug_name,
  kd.approvedSymbol              AS target_symbol,
  url_item.element.url           AS clinical_trial_url
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS kd
LEFT JOIN `bigquery-public-data.open_targets_platform.molecule` AS mol
       ON mol.id = kd.drugId
CROSS JOIN UNNEST(kd.urls.list) AS url_item
WHERE kd.diseaseId = 'EFO_0007416'         -- pancreatic endocrine carcinoma
  AND LOWER(kd.status) = 'completed'       -- only completed trials
ORDER BY drug_name, clinical_trial_url;