SELECT DISTINCT
  t.approvedSymbol AS approved_symbol
FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct` AS a
JOIN `bigquery-public-data.open_targets_platform.targets` AS t
  ON a.targetId = t.id
WHERE a.diseaseId = 'EFO_0000676'
  AND LOWER(a.datasourceId) = 'impc'
QUALIFY RANK() OVER (ORDER BY a.score DESC) = 1;