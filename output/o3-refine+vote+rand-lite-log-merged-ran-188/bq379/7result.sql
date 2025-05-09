WITH
  psoriasis_disease AS (
    -- Identify the diseaseId for psoriasis
    SELECT id AS diseaseId
    FROM `bigquery-public-data.open_targets_platform.diseases`
    WHERE LOWER(name) LIKE '%psoriasis%'
    LIMIT 1
  ),
  psoriasis_associations AS (
    -- All overall association scores for psoriasis
    SELECT a.targetId,
           a.score
    FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect` a
    JOIN psoriasis_disease p
      ON a.diseaseId = p.diseaseId
  ),
  mean_score AS (
    -- Mean overall association score for psoriasis
    SELECT AVG(score) AS avg_score
    FROM psoriasis_associations
  ),
  closest_target AS (
    -- Target whose score is closest to the mean
    SELECT
      targetId,
      score,
      ABS(score - (SELECT avg_score FROM mean_score)) AS diff
    FROM psoriasis_associations
    ORDER BY diff
    LIMIT 1
  )
-- Return its approved gene symbol
SELECT t.approvedSymbol
FROM closest_target c
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = c.targetId;