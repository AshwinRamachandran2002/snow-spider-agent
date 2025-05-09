-- Target genes with the highest IMPC overall score for disease EFO_0000676
WITH impc_associations AS (
  SELECT
    targetId,
    score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE
    diseaseId = 'EFO_0000676'
    AND LOWER(datasourceId) = 'impc'
),
top_score AS (
  SELECT MAX(score) AS max_score
  FROM impc_associations
)
SELECT DISTINCT
  t.approvedSymbol
FROM impc_associations a
JOIN top_score s
  ON a.score = s.max_score
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = a.targetId;