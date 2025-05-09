WITH ranked_targets AS (
  SELECT
    a.targetId,
    t.approvedSymbol,
    a.score,
    RANK() OVER (ORDER BY a.score DESC) AS rnk
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect` AS a
  JOIN `bigquery-public-data.open_targets_platform.targets` AS t
    ON a.targetId = t.id
  WHERE a.datasourceId = 'impc'
    AND a.diseaseId   = 'EFO_0000676'
)

SELECT DISTINCT
  approvedSymbol
FROM ranked_targets
WHERE rnk = 1;