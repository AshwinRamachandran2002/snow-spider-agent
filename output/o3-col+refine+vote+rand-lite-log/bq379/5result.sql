-- Target whose overall-association score is closest to the mean score for psoriasis
WITH mean_val AS (
  SELECT AVG(score) AS mean_score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = 'EFO_0000676'          -- psoriasis
),
ranked_targets AS (
  SELECT
    a.targetId,
    a.score,
    ABS(a.score - m.mean_score) AS distance_from_mean,
    ROW_NUMBER() OVER (ORDER BY ABS(a.score - m.mean_score)) AS rn
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect` AS a
  CROSS JOIN mean_val AS m
  WHERE a.diseaseId = 'EFO_0000676'
)
SELECT
  t.approvedSymbol
FROM ranked_targets AS r
JOIN `bigquery-public-data.open_targets_platform.targets` AS t
  ON t.id = r.targetId
WHERE r.rn = 1;