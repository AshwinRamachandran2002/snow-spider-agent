-- Approved symbol(s) of the target gene(s) with the highest IMPC
-- association score for disease 'EFO_0000676'
WITH impc_assoc AS (
  -- IMPC associations (direct)
  SELECT `targetId`, `score`
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE LOWER(`datasourceId`) = 'impc'
    AND `diseaseId` = 'EFO_0000676'
  UNION ALL
  -- IMPC associations (indirect)
  SELECT `targetId`, `score`
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE LOWER(`datasourceId`) = 'impc'
    AND `diseaseId` = 'EFO_0000676'
),
max_val AS (
  SELECT MAX(`score`) AS max_score
  FROM impc_assoc
)
SELECT DISTINCT t.`approvedSymbol`
FROM impc_assoc a
JOIN max_val m
  ON a.`score` = m.max_score
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.`id` = a.`targetId`;