SELECT t.approvedSymbol
FROM `bigquery-public-data.open_targets_platform.associationByDatasourceDirect` ad
JOIN `bigquery-public-data.open_targets_platform.associationByOverallDirect` aod
ON ad.targetId = aod.targetId AND ad.diseaseId = aod.diseaseId
JOIN `bigquery-public-data.open_targets_platform.targets` t
ON ad.targetId = t.id
WHERE ad.diseaseId = 'EFO_0000676' AND ad.datasourceId = 'impc'
ORDER BY aod.score DESC
LIMIT 1