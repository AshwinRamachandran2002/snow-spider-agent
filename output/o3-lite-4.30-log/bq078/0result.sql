WITH impc_scores AS (
  SELECT
    a.targetId,
    a.score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct` AS a
  WHERE a.diseaseId = 'EFO_0000676'
    AND LOWER(a.datasourceId) = 'impc'
),
max_score AS (
  SELECT MAX(score) AS max_score
  FROM impc_scores
)
SELECT
  t.approvedSymbol AS approved_symbol
FROM impc_scores AS s
JOIN max_score AS m
  ON s.score = m.max_score
JOIN `bigquery-public-data.open_targets_platform.targets` AS t
  ON t.id = s.targetId;