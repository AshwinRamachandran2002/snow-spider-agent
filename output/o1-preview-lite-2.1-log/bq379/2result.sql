WITH mean_score_cte AS (
  SELECT AVG(score) AS mean_score
  FROM `open-targets-prod.platform.associationByOverallDirect`
  WHERE diseaseId = 'EFO_0000676'
)
SELECT t.approvedSymbol
FROM `open-targets-prod.platform.associationByOverallDirect` AS a
JOIN `open-targets-prod.platform.targets` AS t
  ON a.targetId = t.id
CROSS JOIN mean_score_cte
WHERE a.diseaseId = 'EFO_0000676'
ORDER BY ABS(a.score - mean_score_cte.mean_score) ASC
LIMIT 1;