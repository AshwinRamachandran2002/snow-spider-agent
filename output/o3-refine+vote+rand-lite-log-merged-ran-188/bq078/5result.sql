-- Highest-scoring IMPC targets for disease EFO_0000676 and their approved symbols
WITH impc_assoc AS (
  -- Direct associations
  SELECT targetId, score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE datasourceId = 'impc'
    AND diseaseId    = 'EFO_0000676'

  UNION ALL
  
  -- Indirect associations
  SELECT targetId, score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE datasourceId = 'impc'
    AND diseaseId    = 'EFO_0000676'
),
max_score AS (
  SELECT MAX(score) AS val
  FROM impc_assoc
)
SELECT DISTINCT
  t.approvedSymbol
FROM impc_assoc a
JOIN max_score m
  ON a.score = m.val
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = a.targetId
ORDER BY t.approvedSymbol;