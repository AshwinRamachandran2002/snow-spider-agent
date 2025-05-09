WITH psoriasis_targets AS (
    SELECT 
        "targetId",
        "score"
    FROM OPEN_TARGETS_PLATFORM_1.PLATFORM.ASSOCIATIONBYOVERALLDIRECT
    WHERE "diseaseId" = 'EFO_0000676'      -- psoriasis
),
mean_score AS (
    SELECT 
        AVG("score") AS "avg_score"
    FROM psoriasis_targets
),
distance_to_mean AS (
    SELECT 
        p."targetId",
        p."score",
        ABS(p."score" - m."avg_score") AS "diff_from_mean"
    FROM psoriasis_targets p
    CROSS JOIN mean_score m
)
SELECT 
    t."approvedSymbol"
FROM distance_to_mean d
JOIN OPEN_TARGETS_PLATFORM_1.PLATFORM.TARGETS t
     ON t."id" = d."targetId"
ORDER BY 
    d."diff_from_mean" ASC NULLS LAST
FETCH FIRST 1 ROWS ONLY;