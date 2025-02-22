-- Task: For each target associated with psoriasis, compute the distance of its association score from the mean score.
WITH disease_associations AS (
    SELECT "targetId", "score"
    FROM "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."ASSOCIATIONBYOVERALLDIRECT"
    WHERE "diseaseId" = 'EFO_0000676'
),
mean_score AS (
    SELECT AVG("score") AS "mean_score"
    FROM disease_associations
)
SELECT da."targetId", da."score", ABS(da."score" - ms."mean_score") AS "distance"
FROM disease_associations da, mean_score ms;