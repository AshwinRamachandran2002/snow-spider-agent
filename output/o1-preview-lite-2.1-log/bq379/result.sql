SELECT t.approvedSymbol
FROM `open-targets-prod.platform.associationByOverallDirect` AS a
JOIN `open-targets-prod.platform.targets` AS t
ON a.targetId = t.id
WHERE a.diseaseId = 'EFO_0000676'
ORDER BY ABS(a.score - (
    SELECT AVG(score)
    FROM `open-targets-prod.platform.associationByOverallDirect`
    WHERE diseaseId = 'EFO_0000676'
)) ASC
LIMIT 1;