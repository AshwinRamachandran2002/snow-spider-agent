WITH
-- best test score obtained by ANY model that is NOT a “Stack” model
NON_STACK_MAX AS (
    SELECT
        "name",
        "version",
        "step",
        MAX("test_score") AS "max_non_stack_score"
    FROM STACKING.STACKING."MODEL_SCORE"
    WHERE UPPER("model") <> 'STACK'
      AND "step" IN (1,2,3)
    GROUP BY "name","version","step"
),

-- test-score of the “Stack” model for the very same (name,version,step)
STACK_SCORE AS (
    SELECT
        "name",
        "version",
        "step",
        "test_score" AS "stack_score"
    FROM STACKING.STACKING."MODEL_SCORE"
    WHERE UPPER("model") = 'STACK'
      AND "step" IN (1,2,3)
),

-- keep the (name,version,step) triples where the Stack model beats ALL non-Stack models
STACK_BETTER AS (
    SELECT
        n."name"
    FROM NON_STACK_MAX n
    JOIN STACK_SCORE  s
      ON n."name"    = s."name"
     AND n."version" = s."version"
     AND n."step"    = s."step"
    WHERE n."max_non_stack_score" < s."stack_score"
),

-- how many times (across versions & steps 1-3) this happens for each problem
STACK_BETTER_CNT AS (
    SELECT
        "name",
        COUNT(*) AS "nb_stack_better"
    FROM STACK_BETTER
    GROUP BY "name"
),

-- how many rows each problem has in the SOLUTION table
SOLUTION_CNT AS (
    SELECT
        "name",
        COUNT(*) AS "nb_in_solution"
    FROM STACKING.STACKING."SOLUTION"
    GROUP BY "name"
)

-- final answer: problems where the first count exceeds the second
SELECT
    s."name"
FROM STACK_BETTER_CNT s
JOIN SOLUTION_CNT  c
  ON s."name" = c."name"
WHERE s."nb_stack_better" > c."nb_in_solution";