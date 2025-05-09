WITH better AS (
    SELECT s."name"
    FROM "model_score" AS s
    JOIN (
        SELECT "name", "version", "step", MAX("test_score") AS max_non_stack
        FROM "model_score"
        WHERE "model" <> 'Stack'
          AND "step" IN (1,2,3)
        GROUP BY "name", "version", "step"
    ) AS n
      ON s."name" = n."name"
     AND s."version" = n."version"
     AND s."step" = n."step"
    WHERE s."model" = 'Stack'
      AND s."step" IN (1,2,3)
      AND s."test_score" > n.max_non_stack
),
cnt_better AS (
    SELECT "name", COUNT(*) AS cnt_better
    FROM better
    GROUP BY "name"
),
cnt_solution AS (
    SELECT "name", COUNT(*) AS cnt_sol
    FROM "solution"
    GROUP BY "name"
)
SELECT cb."name" AS problem
FROM   cnt_better  AS cb
JOIN   cnt_solution AS cs ON cb."name" = cs."name"
WHERE  cb.cnt_better > cs.cnt_sol
ORDER BY cb."name";