-- Target whose overall association score for psoriasis (EFO_0000676)
-- is closest to the mean score across all targets
WITH mean_val AS (
  SELECT AVG(score) AS mean_score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = 'EFO_0000676'
),
closest AS (
  SELECT targetId,
         score,
         ABS(score - m.mean_score) AS diff_to_mean
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`, mean_val AS m
  WHERE diseaseId = 'EFO_0000676'
  ORDER BY diff_to_mean
  LIMIT 1
)
SELECT t.approvedSymbol
FROM closest c
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = c.targetId;