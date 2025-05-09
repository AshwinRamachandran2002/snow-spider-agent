WITH ranked AS (
  SELECT
    targetId,
    score,
    MAX(score) OVER() AS max_score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE datasourceId = 'impc'
    AND diseaseId    = 'EFO_0000676'
)
SELECT DISTINCT
  t.approvedSymbol
FROM ranked r
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = r.targetId
WHERE r.score = r.max_score
ORDER BY t.approvedSymbol;