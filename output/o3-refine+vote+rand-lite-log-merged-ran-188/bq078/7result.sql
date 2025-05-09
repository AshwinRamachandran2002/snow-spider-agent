WITH impc_targets AS (
  -- Targets linked to the disease via the IMPC datasource (direct + indirect tables)
  SELECT DISTINCT targetId
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_indirect`
  WHERE datasourceId = 'impc'
    AND diseaseId    = 'EFO_0000676'
  UNION DISTINCT
  SELECT DISTINCT targetId
  FROM `bigquery-public-data.open_targets_platform.association_by_datasource_direct`
  WHERE datasourceId = 'impc'
    AND diseaseId    = 'EFO_0000676'
),
scored AS (
  -- Overall scores (indirect overall table) for those IMPC targets
  SELECT o.targetId, o.score
  FROM `bigquery-public-data.open_targets_platform.association_by_overall_indirect` AS o
  JOIN impc_targets AS i
    ON o.targetId = i.targetId
  WHERE o.diseaseId = 'EFO_0000676'
),
top_score AS (
  SELECT MAX(score) AS max_score
  FROM scored
)
SELECT DISTINCT t.approvedSymbol
FROM scored s
JOIN top_score ts
  ON s.score = ts.max_score
JOIN `bigquery-public-data.open_targets_platform.targets` AS t
  ON t.id = s.targetId;