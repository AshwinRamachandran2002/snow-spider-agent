WITH psoriasis AS (
  SELECT id
  FROM `bigquery-public-data.open_targets_platform.diseases`
  WHERE LOWER(name) = 'psoriasis'
  LIMIT 1
),
assoc AS (
  SELECT targetId, score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = (SELECT id FROM psoriasis)
    AND score IS NOT NULL
),
stats AS (
  SELECT AVG(score) AS mean_score
  FROM assoc
),
ranked AS (
  SELECT
    targetId,
    score,
    ABS(score - (SELECT mean_score FROM stats)) AS diff
  FROM assoc
)
SELECT
  t.approvedSymbol
FROM ranked r
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = r.targetId
ORDER BY r.diff ASC
LIMIT 1;