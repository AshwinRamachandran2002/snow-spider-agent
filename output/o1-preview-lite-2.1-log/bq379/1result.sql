WITH avg_score AS (
    SELECT AVG(score) AS mean_score
    FROM `open-targets-prod.platform.associationByOverallDirect`
    WHERE diseaseId = 'EFO_0000676'
),
score_diffs AS (
    SELECT a.targetId, a.score, ABS(a.score - avg_score.mean_score) AS score_diff
    FROM `open-targets-prod.platform.associationByOverallDirect` a, avg_score
    WHERE a.diseaseId = 'EFO_0000676'
),
min_diff AS (
    SELECT MIN(score_diff) AS min_score_diff
    FROM score_diffs
),
closest_targets AS (
    SELECT sd.targetId, sd.score, sd.score_diff
    FROM score_diffs sd, min_diff md
    WHERE sd.score_diff = md.min_score_diff
)
SELECT t.approvedSymbol
FROM closest_targets ct
JOIN `open-targets-prod.platform.targets` t ON ct.targetId = t.id
LIMIT 1;