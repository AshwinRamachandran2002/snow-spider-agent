WITH disease_associations AS (
    SELECT "targetId", "score"
    FROM "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."ASSOCIATIONBYOVERALLDIRECT"
    WHERE "diseaseId" = 'EFO_0000676'
),
mean_score AS (
    SELECT AVG("score") AS "mean_score"
    FROM disease_associations
),
target_distance AS (
    SELECT da."targetId", da."score", ABS(da."score" - ms."mean_score") AS "distance"
    FROM disease_associations da, mean_score ms
),
closest_target AS (
    SELECT "targetId", "score"
    FROM target_distance
    ORDER BY "distance"
    LIMIT 1
)
SELECT t."approvedSymbol" AS "approved_symbol", ROUND(ct."score", 4) AS "association_score"
FROM closest_target ct
JOIN "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."TARGETS" t
ON ct."targetId" = t."id";