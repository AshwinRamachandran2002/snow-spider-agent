-- Task: Retrieve the approved symbol, target ID, data source ID, and overall score of the target gene with the highest overall score among those associated with the disease 'EFO_0000676' from the data source 'IMPC'. Limit the result to the top one gene.
SELECT
  T1.targetId AS target_id,
  T1.datasourceId,
  targets.approvedSymbol AS approved_symbol,
  overall_associations.score AS overall_score
FROM
  `bigquery-public-data.open_targets_platform.associationByDatasourceDirect` as T1
JOIN
  `bigquery-public-data.open_targets_platform.targets` AS targets
ON
  T1.targetId = targets.id
JOIN
  `bigquery-public-data.open_targets_platform.associationByOverallDirect` AS overall_associations
ON
  T1.targetId = overall_associations.targetId
WHERE
  overall_associations.diseaseId = 'EFO_0000676' AND T1.datasourceId = 'impc'
ORDER BY
  overall_associations.score DESC
LIMIT
 1;