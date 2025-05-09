-- Approved symbol(s) of target genes with the highest overall IMPC
-- association score for disease 'EFO_0000676'
WITH impc_scores AS (
  -- Direct evidence
  SELECT
    targetId,
    score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE
    diseaseId = 'EFO_0000676'
    AND LOWER(datasourceId) = 'impc'

  UNION ALL

  -- Indirect evidence
  SELECT
    targetId,
    score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE
    diseaseId = 'EFO_0000676'
    AND LOWER(datasourceId) = 'impc'
),
target_max_score AS (
  -- Best score per target
  SELECT
    targetId,
    MAX(score) AS max_score
  FROM impc_scores
  GROUP BY targetId
),
top_score AS (
  -- Highest score observed
  SELECT
    MAX(max_score) AS highest_score
  FROM target_max_score
)
SELECT DISTINCT
  tg.approvedSymbol
FROM target_max_score AS tms
JOIN top_score AS ts
  ON tms.max_score = ts.highest_score
JOIN `bigquery-public-data.open_targets_platform.targets` AS tg
  ON tg.id = tms.targetId
ORDER BY
  tg.approvedSymbol;