-- Approved gene symbol(s) for the target(s) with the highest IMPC overall score
-- in association with disease EFO_0000676
WITH impc_scores AS (
  SELECT
    targetId,
    score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE datasourceId = 'impc'
    AND diseaseId   = 'EFO_0000676'
),
max_score AS (
  SELECT MAX(score) AS top_score
  FROM impc_scores
)
SELECT DISTINCT
  t.approvedSymbol
FROM impc_scores s
JOIN max_score m
  ON s.score = m.top_score
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON s.targetId = t.id
ORDER BY t.approvedSymbol;