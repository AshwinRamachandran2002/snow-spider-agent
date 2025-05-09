WITH psoriasis_scores AS (
  SELECT targetId, score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect`
  WHERE diseaseId = 'EFO_0000676'            -- psoriasis
),
stats AS (
  SELECT AVG(score) AS mean_score
  FROM psoriasis_scores
),
closest AS (
  SELECT targetId
  FROM psoriasis_scores, stats
  ORDER BY ABS(score - mean_score)
  LIMIT 1
)
SELECT t.approvedSymbol
FROM closest c
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = c.targetId;