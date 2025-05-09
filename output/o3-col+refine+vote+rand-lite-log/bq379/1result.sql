WITH psoriasis_scores AS (
  SELECT
    targetId,
    score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = 'EFO_0000676'         -- psoriasis
),
mean_score AS (
  SELECT
    AVG(score) AS avg_score
  FROM psoriasis_scores
),
closest AS (
  SELECT
    targetId,
    score,
    ABS(score - avg_score) AS distance_to_mean,
    ROW_NUMBER() OVER (ORDER BY ABS(score - avg_score)) AS rn
  FROM psoriasis_scores, mean_score
)
SELECT
  t.approvedSymbol
FROM closest c
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = c.targetId
WHERE c.rn = 1;