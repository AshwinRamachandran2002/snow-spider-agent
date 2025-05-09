-- Target (approvedSymbol) whose overall association score is closest
-- to the mean overall-association score for psoriasis (EFO_0000676)

WITH psor_scores AS (
  SELECT
    targetId,
    score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = 'EFO_0000676'                 -- psoriasis
),
mean_score AS (
  SELECT AVG(score) AS avg_score
  FROM psor_scores
),
ranked AS (
  SELECT
    targetId,
    score,
    ABS(score - (SELECT avg_score FROM mean_score)) AS diff,
    RANK() OVER (ORDER BY ABS(score - (SELECT avg_score FROM mean_score))) AS rnk
  FROM psor_scores
)
SELECT
  t.approvedSymbol
FROM ranked r
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = r.targetId
WHERE r.rnk = 1
LIMIT 1;