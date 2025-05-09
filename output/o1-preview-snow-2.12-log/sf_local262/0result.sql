WITH solution_counts AS (
    SELECT "name", COUNT(*) AS "solution_count"
    FROM "STACKING"."STACKING"."SOLUTION"
    GROUP BY "name"
),
model_score_counts AS (
    SELECT "name", COUNT(*) AS "model_score_count"
    FROM "STACKING"."STACKING"."MODEL_SCORE"
    WHERE "step" IN (1, 2, 3)
    GROUP BY "name"
),
problems_with_more_model_counts AS (
    SELECT msc."name"
    FROM model_score_counts msc
    JOIN solution_counts sc ON msc."name" = sc."name"
    WHERE msc."model_score_count" > sc."solution_count"
),
non_stack_max_scores AS (
    SELECT "name", "version", "step", MAX("test_score") AS "max_non_stack_score"
    FROM "STACKING"."STACKING"."MODEL_SCORE"
    WHERE LOWER("model") <> 'stack' AND "step" IN (1, 2, 3)
    GROUP BY "name", "version", "step"
),
stack_scores AS (
    SELECT "name", "version", "step", "test_score" AS "stack_score"
    FROM "STACKING"."STACKING"."MODEL_SCORE"
    WHERE LOWER("model") = 'stack' AND "step" IN (1, 2, 3)
),
comparisons AS (
    SELECT DISTINCT ss."name"
    FROM stack_scores ss
    JOIN non_stack_max_scores nss ON ss."name" = nss."name" AND ss."version" = nss."version" AND ss."step" = nss."step"
    WHERE ss."stack_score" > nss."max_non_stack_score"
)
SELECT DISTINCT pwmmc."name" AS "Problem_Name"
FROM problems_with_more_model_counts pwmmc
JOIN comparisons c ON pwmmc."name" = c."name";