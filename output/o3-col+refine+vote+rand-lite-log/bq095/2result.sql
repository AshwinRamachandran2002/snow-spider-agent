-- Drugs with COMPLETED clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
SELECT
  mol.name                                                AS drug_name,
  tgt.approvedSymbol                                      AS target_symbol,
  ARRAY_TO_STRING(
      ARRAY_AGG(DISTINCT url.element.url ORDER BY url.element.url),
      ' | '
  )                                                       AS clinical_trial_links
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS kd
JOIN `bigquery-public-data.open_targets_platform.molecule`              AS mol
  ON kd.drugId = mol.id
JOIN `bigquery-public-data.open_targets_platform.targets`               AS tgt
  ON kd.targetId = tgt.id
LEFT JOIN UNNEST(kd.urls.list) AS url
WHERE kd.diseaseId = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND LOWER(kd.status) = 'completed'         -- trial status
GROUP BY
  drug_name,
  target_symbol
ORDER BY
  drug_name;