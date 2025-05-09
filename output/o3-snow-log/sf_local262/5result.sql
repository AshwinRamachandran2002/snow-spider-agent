WITH "stack_vs_non" AS (
    SELECT
        ms."name",
        ms."version",
        ms."step",
        MAX(CASE WHEN UPPER(ms."model") LIKE '%STACK%' THEN ms."test_score" END) AS "stack_score",
        MAX(CASE WHEN UPPER(ms."model") NOT LIKE '%STACK%' THEN ms."test_score" END) AS "non_stack_max_score"
    FROM STACKING.STACKING.MODEL_SCORE ms
    WHERE ms."step" IN (1, 2, 3)
    GROUP BY ms."name", ms."version", ms."step"
),
"better_stack" AS (
    SELECT
        "name"
    FROM "stack_vs_non"
    WHERE "stack_score" IS NOT NULL
      AND "non_stack_max_score" IS NOT NULL
      AND "stack_score" > "non_stack_max_score"
),
"cnt_better" AS (
    SELECT
        "name",
        COUNT(*) AS "cnt_better"
    FROM "better_stack"
    GROUP BY "name"
),
"solution_cnt" AS (
    SELECT
        "name",
        COUNT(*) AS "cnt_solution"
    FROM STACKING.STACKING.SOLUTION
    GROUP BY "name"
)
SELECT
    cb."name"
FROM "cnt_better" cb
JOIN "solution_cnt" sc
  ON cb."name" = sc."name"
WHERE cb."cnt_better" > sc."cnt_solution";