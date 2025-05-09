SELECT
  kd.prefName                                         AS drug_name,
  kd.approvedSymbol                                   AS target_gene,
  ARRAY_AGG(DISTINCT urlStruct.element.url
            ORDER BY urlStruct.element.url)           AS clinical_trial_urls
FROM   `bigquery-public-data.open_targets_platform.knownDrugsAggregated` AS kd
JOIN   `bigquery-public-data.open_targets_platform.molecule`             AS mol
       ON mol.id = kd.drugId                               -- ensure drug has molecular metadata
CROSS  JOIN UNNEST(kd.urls.list) AS urlStruct              -- pull individual trial links
WHERE  kd.diseaseId = 'EFO_0007416'                        -- pancreatic endocrine carcinoma
  AND  LOWER(kd.status) = 'completed'                      -- completed clinical trials only
GROUP  BY drug_name, target_gene
ORDER  BY drug_name;