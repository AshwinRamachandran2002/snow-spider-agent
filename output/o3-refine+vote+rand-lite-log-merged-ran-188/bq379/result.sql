WITH psoriasis_id AS (
  -- Identify the diseaseId corresponding to psoriasis
  SELECT id
  FROM `bigquery-public-data.open_targets_platform.diseases`
  WHERE LOWER(name) = 'psoriasis'
  LIMIT 1
),
psoriasis_scores AS (
  -- All overall association scores for psoriasis across targets
  SELECT targetId, score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = (SELECT id FROM psoriasis_id)
),
mean_score AS (
  -- Mean overall association score for psoriasis
  SELECT AVG(score) AS avg_psoriasis_score
  FROM psoriasis_scores
),
ranked_targets AS (
  -- Distance of each target’s score from the mean
  SELECT
    ps.targetId,
    ps.score,
    ABS(ps.score - ms.avg_psoriasis_score) AS distance_to_mean
  FROM psoriasis_scores ps
  CROSS JOIN mean_score ms
)
-- Target whose score is closest to the mean
SELECT
  t.approvedSymbol
FROM ranked_targets rt
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = rt.targetId
ORDER BY rt.distance_to_mean
LIMIT 1;