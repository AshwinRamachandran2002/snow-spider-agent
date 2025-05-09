-- Retrieve the approved symbol(s) of the target gene(s) with the highest IMPC
-- association score for disease EFO_0000676 (across both direct & indirect IMPC data)

WITH impc_scores AS (
  -- Collect IMPC scores (direct + indirect) for the specified disease
  SELECT targetId, score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE LOWER(datasourceId) = 'impc'
    AND diseaseId = 'EFO_0000676'

  UNION ALL

  SELECT targetId, score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE LOWER(datasourceId) = 'impc'
    AND diseaseId = 'EFO_0000676'
),
best_per_target AS (
  -- Keep the highest score per target
  SELECT targetId, MAX(score) AS score
  FROM impc_scores
  GROUP BY targetId
),
ranked AS (
  -- Rank targets by their best score (highest first)
  SELECT
    bpt.targetId,
    t.approvedSymbol,
    bpt.score,
    RANK() OVER (ORDER BY bpt.score DESC) AS rnk
  FROM best_per_target bpt
  JOIN `bigquery-public-data.open_targets_platform.targets` t
    ON t.id = bpt.targetId
)
-- Return the approved symbol(s) with the top (highest) score
SELECT approvedSymbol
FROM ranked
WHERE rnk = 1;