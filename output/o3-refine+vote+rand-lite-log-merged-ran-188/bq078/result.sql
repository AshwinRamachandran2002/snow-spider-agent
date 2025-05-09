-- Retrieve the gene symbol(s) with the single highest IMPC-specific association
-- score (considering both direct and indirect evidence) for disease EFO_0000676
WITH combined AS (
  -- Direct evidence
  SELECT
    `targetId`,
    `score`
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE `diseaseId`   = 'EFO_0000676'
    AND `datasourceId` = 'impc'

  UNION ALL

  -- Indirect evidence
  SELECT
    `targetId`,
    `score`
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE `diseaseId`   = 'EFO_0000676'
    AND `datasourceId` = 'impc'
),
agg AS (
  -- Keep the best score per target
  SELECT
    `targetId`,
    MAX(`score`) AS max_score
  FROM combined
  GROUP BY `targetId`
),
ranked AS (
  -- Rank targets by their best score
  SELECT
    `targetId`,
    max_score,
    DENSE_RANK() OVER (ORDER BY max_score DESC) AS rnk
  FROM agg
)
SELECT
  t.`approvedSymbol`
FROM ranked r
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.`id` = r.`targetId`
WHERE r.rnk = 1;