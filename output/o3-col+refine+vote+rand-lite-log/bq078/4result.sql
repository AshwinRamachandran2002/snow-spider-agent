-- Approved gene symbols whose IMPC datasource score is the highest for disease EFO_0000676
WITH impc_scores AS (
  SELECT
    targetId,
    score,
    MAX(score) OVER () AS max_score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE diseaseId   = 'EFO_0000676'   -- disease of interest
    AND datasourceId = 'impc'         -- IMPC datasource
)
SELECT DISTINCT t.approvedSymbol
FROM impc_scores s
JOIN `bigquery-public-data.open_targets_platform.targets` t
  ON t.id = s.targetId
WHERE s.score = s.max_score;