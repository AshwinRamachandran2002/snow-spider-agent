WITH psoriasis_scores AS (
  SELECT
    targetId,
    score
  FROM
    `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE
    diseaseId = 'EFO_0000676'    -- psoriasis
),

mean_score AS (
  SELECT
    AVG(score) AS avg_score
  FROM
    psoriasis_scores
),

closest_target AS (
  SELECT
    targetId
  FROM (
    SELECT
      targetId,
      ABS(score - (SELECT avg_score FROM mean_score)) AS distance_to_mean,
      ROW_NUMBER() OVER (ORDER BY ABS(score - (SELECT avg_score FROM mean_score))) AS rn
    FROM
      psoriasis_scores
  )
  WHERE rn = 1
)

SELECT
  t.approvedSymbol
FROM
  closest_target ct
JOIN
  `bigquery-public-data.open_targets_platform.targets` t
ON
  t.id = ct.targetId;