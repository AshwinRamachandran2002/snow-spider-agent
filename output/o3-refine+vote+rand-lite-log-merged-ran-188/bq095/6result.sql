-- Drugs with COMPLETED clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
SELECT DISTINCT
  mol.name                         AS drug_name,
  kda.approvedSymbol               AS target_approved_symbol,
  url.element.url                  AS clinical_trial_url
FROM `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS kda
JOIN `bigquery-public-data.open_targets_platform.molecule`             AS mol
  ON kda.drugId = mol.id
LEFT JOIN UNNEST(kda.urls.list) AS url
WHERE kda.diseaseId = 'EFO_0007416'          -- pancreatic endocrine carcinoma
  AND LOWER(kda.status) = 'completed'        -- only completed trials
  AND url.element.url IS NOT NULL            -- retain rows with a trial link
ORDER BY
  drug_name,
  clinical_trial_url;