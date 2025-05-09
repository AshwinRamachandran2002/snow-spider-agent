-- Target whose overall association score is closest to the mean for psoriasis
WITH mean_tbl AS (
  SELECT AVG(score) AS mean_score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = 'EFO_0000676'         -- psoriasis
),
ranked AS (
  SELECT
    targetId,
    ABS(score - (SELECT mean_score FROM mean_tbl)) AS diff_to_mean
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = 'EFO_0000676'
)
SELECT
  t.approvedSymbol
FROM ranked AS r
JOIN `bigquery-public-data.open_targets_platform.targets` AS t
  ON t.id = r.targetId
ORDER BY r.diff_to_mean
LIMIT 1;