-- Drugs with COMPLETED clinical trials for pancreatic endocrine carcinoma (EFO_0007416)
-- plus their target symbol and associated clinical-trial URLs
SELECT DISTINCT
  COALESCE(mol.`name`, kd.`prefName`)     AS drug_name,
  kd.`approvedSymbol`                     AS target_approved_symbol,
  url.element.url                         AS clinical_trial_url
FROM   `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS kd
JOIN   `bigquery-public-data.open_targets_platform.molecule`             AS mol
       ON mol.`id` = kd.`drugId`,
       UNNEST(kd.`urls`.list) AS url
WHERE  kd.`diseaseId` = 'EFO_0007416'
  AND  LOWER(kd.`status`) = 'completed'
ORDER BY drug_name, clinical_trial_url;