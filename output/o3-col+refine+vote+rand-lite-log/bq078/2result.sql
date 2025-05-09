WITH ranked_scores AS (
  SELECT
    targetId,
    score,
    DENSE_RANK() OVER (ORDER BY score DESC) AS rank_num
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE diseaseId = 'EFO_0000676'
    AND LOWER(datasourceId) = 'impc'
)

SELECT DISTINCT
  t.approvedSymbol
FROM ranked_scores AS rs
JOIN `bigquery-public-data.open_targets_platform.targets` AS t
  ON t.id = rs.targetId
WHERE rs.rank_num = 1;