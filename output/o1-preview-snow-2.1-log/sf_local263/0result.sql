WITH stack_scores AS (
    SELECT "name", "version", "step", "test_score"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "model" = 'Stack'
),
nonstack_max_scores AS (
    SELECT "name", "version", "step", MAX("test_score") AS "max_non_stack_score"
    FROM STACKING.STACKING.MODEL_SCORE
    WHERE "model" != 'Stack'
    GROUP BY "name", "version", "step"
),
run_status AS (
    SELECT 
        s."name", 
        s."version", 
        s."step",
        s."test_score" AS "stack_test_score",
        n."max_non_stack_score",
        CASE
            WHEN s."test_score" > n."max_non_stack_score" THEN 'strong'
            WHEN s."test_score" = n."max_non_stack_score" THEN 'soft'
            ELSE 'neither'
        END AS "Status"
    FROM stack_scores s
    JOIN nonstack_max_scores n
        ON s."name" = n."name" 
        AND s."version" = n."version" 
        AND s."step" = n."step"
),
status_L1_model_counts AS (
    SELECT 
        rs."Status", 
        m."L1_model", 
        COUNT(*) AS "Occurrences"
    FROM run_status rs
    JOIN STACKING.STACKING.MODEL m
        ON rs."name" = m."name" 
        AND rs."version" = m."version" 
        AND rs."step" = m."step"
    WHERE rs."Status" IN ('strong', 'soft')
    GROUP BY rs."Status", m."L1_model"
),
ranked_L1_models AS (
    SELECT 
        s."Status", 
        s."L1_model", 
        s."Occurrences",
        RANK() OVER (PARTITION BY s."Status" ORDER BY s."Occurrences" DESC NULLS LAST) AS "rank"
    FROM status_L1_model_counts s
)
SELECT 
    "Status", 
    "L1_model", 
    "Occurrences"
FROM ranked_L1_models
WHERE "rank" = 1
ORDER BY "Status";