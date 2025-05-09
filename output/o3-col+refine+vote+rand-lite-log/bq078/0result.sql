SELECT DISTINCT
  t.approvedSymbol
FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect` AS a
JOIN `bigquery-public-data.open_targets_platform.targets`                           AS t
  ON t.id = a.targetId
WHERE a.datasourceId = 'impc'
  AND a.diseaseId   = 'EFO_0000676'
QUALIFY DENSE_RANK() OVER (ORDER BY a.score DESC) = 1;