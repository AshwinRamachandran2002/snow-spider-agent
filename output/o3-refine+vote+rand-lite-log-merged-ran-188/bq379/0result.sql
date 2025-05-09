/* Target whose overall association score for psoriasis is closest to
   the mean overall association score for psoriasis                  */
WITH psoriasis AS (
  -- get the diseaseId corresponding to psoriasis
  SELECT id
  FROM   `bigquery-public-data.open_targets_platform.diseases`
  WHERE  LOWER(name) = 'psoriasis'
  LIMIT  1
),
psoriasis_scores AS (
  -- overall association scores (indirect) for every target in psoriasis
  SELECT  a.targetId,
          a.score
  FROM    `bigquery-public-data.open_targets_platform.association_by_overall_indirect` AS a
  JOIN    psoriasis AS d
       ON a.diseaseId = d.id
),
mean_score AS (
  -- average score
  SELECT AVG(score) AS mean_val
  FROM   psoriasis_scores
),
closest AS (
  -- find the score closest to the mean
  SELECT  targetId,
          score,
          ABS(score - m.mean_val) AS delta
  FROM    psoriasis_scores, mean_score AS m
  ORDER BY delta
  LIMIT 1
)
SELECT t.approvedSymbol
FROM   closest AS c
JOIN   `bigquery-public-data.open_targets_platform.targets` AS t
  ON   t.id = c.targetId;