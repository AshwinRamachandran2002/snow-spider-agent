-- Task: Retrieve the approved symbols of target genes associated with the disease 'EFO_0000676' from the data source 'IMPC'. Limit the results to 100.
SELECT
  T1.targetId AS target_id,
  targets.approvedSymbol AS approved_symbol
FROM
  `bigquery-public-data.open_targets_platform.associationByDatasourceDirect` AS T1
JOIN
  `bigquery-public-data.open_targets_platform.targets` AS targets
ON
  T1.targetId = targets.id
WHERE
  T1.diseaseId = 'EFO_0000676' AND T1.datasourceId = 'impc'
LIMIT
  100;