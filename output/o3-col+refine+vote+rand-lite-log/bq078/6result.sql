WITH impc_scores AS (
  SELECT
    targetId,
    score
  FROM
    `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE
    LOWER(datasourceId) LIKE '%impc%'          -- restrict to IMPC datasource
    AND diseaseId = 'EFO_0000676'              -- target disease
),
max_score AS (
  SELECT
    MAX(score) AS max_score                   -- highest score among IMPC rows
  FROM
    impc_scores
)
SELECT DISTINCT
  t.approvedSymbol                            -- gene symbol(s) with the top score
FROM
  impc_scores s
JOIN
  max_score m
ON
  s.score = m.max_score
JOIN
  `bigquery-public-data.open_targets_platform.targets` t
ON
  s.targetId = t.id;