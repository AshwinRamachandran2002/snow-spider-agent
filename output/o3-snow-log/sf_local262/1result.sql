WITH stack_scores AS (          -- test score of the "Stack" model
    SELECT "name",
           "version",
           "step",
           "test_score"  AS "stack_test"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "step" IN (1,2,3)
      AND UPPER("model") = 'STACK'
),
non_stack_max AS (              -- best test score among all non-Stack models
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS "max_non_stack"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "step" IN (1,2,3)
      AND UPPER("model") <> 'STACK'
    GROUP BY "name","version","step"
),
better_stack AS (               -- keep (name,version,step) where Stack wins
    SELECT s."name",
           s."version",
           s."step"
    FROM stack_scores s
    LEFT JOIN non_stack_max n
           ON  s."name"    = n."name"
           AND s."version" = n."version"
           AND s."step"    = n."step"
    WHERE s."stack_test" > COALESCE(n."max_non_stack", -999)
),
occurrence_count AS (           -- how many winning occurrences per problem
    SELECT "name",
           COUNT(*) AS "occurrences"
    FROM better_stack
    GROUP BY "name"
),
solution_count AS (             -- how many rows each problem has in SOLUTION
    SELECT "name",
           COUNT(*) AS "solution_rows"
    FROM STACKING.STACKING.SOLUTION
    GROUP BY "name"
)
SELECT o."name"
FROM   occurrence_count o
JOIN   solution_count  s
       ON o."name" = s."name"
WHERE  o."occurrences" > s."solution_rows";