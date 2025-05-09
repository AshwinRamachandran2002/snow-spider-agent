WITH Stack_Scores AS (
    SELECT "name", "version", "step", "test_score"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "model" = 'Stack' AND "step" IN (1, 2, 3)
),
Non_Stack_Max_Scores AS (
    SELECT "name", "version", "step", MAX("test_score") AS "max_non_stack_score"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "model" <> 'Stack' AND "step" IN (1, 2, 3)
    GROUP BY "name", "version", "step"
),
Stack_Better AS (
    SELECT s."name", s."version", s."step", s."test_score", ns."max_non_stack_score"
    FROM Stack_Scores s
    JOIN Non_Stack_Max_Scores ns
        ON s."name" = ns."name" AND s."version" = ns."version" AND s."step" = ns."step"
    WHERE s."test_score" > ns."max_non_stack_score"
),
Stack_Better_Count AS (
    SELECT "name", COUNT(*) AS "times_stack_higher"
    FROM Stack_Better
    GROUP BY "name"
),
Solution_Count AS (
    SELECT "name", COUNT(*) AS "total_occurrences"
    FROM STACKING.STACKING.SOLUTION
    GROUP BY "name"
)
SELECT sbc."name"
FROM Stack_Better_Count sbc
JOIN Solution_Count sc ON sbc."name" = sc."name"
WHERE sbc."times_stack_higher" > sc."total_occurrences";