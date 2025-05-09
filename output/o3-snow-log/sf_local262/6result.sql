WITH stack_scores AS (
    SELECT 
        "name",
        "version",
        "step",
        MAX("test_score") AS "stack_test_score"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "step" IN (1,2,3)
      AND UPPER("model") = 'STACK'
    GROUP BY "name", "version", "step"
), 
non_stack_scores AS (
    SELECT 
        "name",
        "version",
        "step",
        MAX("test_score") AS "non_stack_test_score"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "step" IN (1,2,3)
      AND UPPER("model") <> 'STACK'
    GROUP BY "name", "version", "step"
), 
better_stack AS (
    SELECT s."name"
    FROM stack_scores s
    JOIN non_stack_scores n
      ON s."name"   = n."name"
     AND s."version"= n."version"
     AND s."step"   = n."step"
    WHERE s."stack_test_score" > n."non_stack_test_score"
), 
count_better AS (
    SELECT 
        "name",
        COUNT(*) AS "cnt_better"
    FROM better_stack
    GROUP BY "name"
), 
solution_count AS (
    SELECT 
        "name",
        COUNT(*) AS "cnt_solution"
    FROM STACKING.STACKING.SOLUTION
    GROUP BY "name"
)
SELECT 
    b."name"
FROM count_better b
LEFT JOIN solution_count s
       ON b."name" = s."name"
WHERE b."cnt_better" > COALESCE(s."cnt_solution", 0);