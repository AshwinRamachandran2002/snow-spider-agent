-- Approved gene symbols for IMPC targets that achieve the
-- highest overall association score with disease 'EFO_0000676'
WITH impc_pairs AS (
  SELECT
    i.targetId,
    o.score
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect` AS i
  JOIN `bigquery-public-data.open_targets_platform.association_by_overall_indirect`  AS o
    ON  o.diseaseId = i.diseaseId
   AND o.targetId  = i.targetId
  WHERE i.diseaseId   = 'EFO_0000676'
    AND LOWER(i.datasourceId) = 'impc'
),
max_score AS (
  SELECT MAX(score) AS mx FROM impc_pairs
)
SELECT DISTINCT
       t.approvedSymbol
FROM   impc_pairs AS p
JOIN   max_score  AS m  ON p.score = m.mx
JOIN   `bigquery-public-data.open_targets_platform.targets` AS t
       ON t.id = p.targetId;