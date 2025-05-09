SELECT t.approvedSymbol
FROM `bigquery-public-data.open_targets_platform.associationByDatasourceDirect` AS a
JOIN `bigquery-public-data.open_targets_platform.targets` AS t
    ON a.targetId = t.id
JOIN `bigquery-public-data.open_targets_platform.associationByOverallDirect` AS o
    ON a.diseaseId = o.diseaseId AND a.targetId = o.targetId
WHERE a.diseaseId = 'EFO_0000676' AND a.datasourceId = 'impc'
    AND o.score = (
        SELECT MAX(o2.score)
        FROM `bigquery-public-data.open_targets_platform.associationByDatasourceDirect` AS a2
        JOIN `bigquery-public-data.open_targets_platform.associationByOverallDirect` AS o2
            ON a2.diseaseId = o2.diseaseId AND a2.targetId = o2.targetId
        WHERE a2.diseaseId = 'EFO_0000676' AND a2.datasourceId = 'impc'
    );