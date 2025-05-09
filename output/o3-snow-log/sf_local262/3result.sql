WITH "MODEL_SCORES" AS (
    SELECT 
        "name",
        "version",
        "step",
        "model",
        "test_score"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "step" IN (1, 2, 3)
),

/* best “Stack” model score (model name contains ‘STACK’, case-insensitive) */
"STACK_SCORES" AS (
    SELECT
        "name",
        "version",
        "step",
        MAX("test_score") AS "stack_score"
    FROM "MODEL_SCORES"
    WHERE UPPER("model") LIKE '%STACK%'
    GROUP BY "name", "version", "step"
),

/* best non-“Stack” model score */
"NON_STACK_SCORES" AS (
    SELECT
        "name",
        "version",
        "step",
        MAX("test_score") AS "non_stack_score"
    FROM "MODEL_SCORES"
    WHERE UPPER("model") NOT LIKE '%STACK%'
    GROUP BY "name", "version", "step"
),

/* steps where the “Stack” model beats every non-“Stack” model */
"STACK_BETTER" AS (
    SELECT
        s."name",
        s."version",
        s."step"
    FROM "STACK_SCORES"  s
    JOIN "NON_STACK_SCORES" n
      ON s."name"    = n."name"
     AND s."version" = n."version"
     AND s."step"    = n."step"
    WHERE s."stack_score" > n."non_stack_score"
),

/* number of such victorious steps per problem */
"NB_STACK_BETTER" AS (
    SELECT
        "name",
        COUNT(*) AS "better_cnt"
    FROM "STACK_BETTER"
    GROUP BY "name"
),

/* total number of rows each problem has in SOLUTION table */
"SOLUTION_CNT" AS (
    SELECT
        "name",
        COUNT(*) AS "solution_cnt"
    FROM STACKING.STACKING.SOLUTION
    GROUP BY "name"
)

/* final answer: problems whose victorious-step count exceeds their solution rows */
SELECT
    b."name"
FROM "NB_STACK_BETTER" b
JOIN "SOLUTION_CNT"  s
  ON b."name" = s."name"
WHERE b."better_cnt" > s."solution_cnt";