WITH psoriasis_associations AS (
    SELECT
        ao."targetId",
        ao."score"
    FROM
        "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."ASSOCIATIONBYOVERALLDIRECT" ao
    WHERE
        ao."diseaseId" = 'EFO_0000676'
),
mean_score AS (
    SELECT AVG("score") AS mean_score FROM psoriasis_associations
),
target_diff AS (
    SELECT
        pa."targetId",
        pa."score",
        ABS(pa."score" - ms.mean_score) AS diff
    FROM
        psoriasis_associations pa
        CROSS JOIN mean_score ms
),
min_diff AS (
    SELECT MIN(diff) AS min_diff FROM target_diff
),
closest_target AS (
    SELECT
        td."targetId",
        td."score"
    FROM
        target_diff td
        JOIN min_diff md ON td.diff = md.min_diff
        LIMIT 1
),
result AS (
    SELECT
        t."approvedSymbol",
        ROUND(ct."score", 4) AS "association_score"
    FROM
        closest_target ct
        JOIN "OPEN_TARGETS_PLATFORM_1"."PLATFORM"."TARGETS" t
        ON t."id" = ct."targetId"
)
SELECT
    *
FROM
    result;