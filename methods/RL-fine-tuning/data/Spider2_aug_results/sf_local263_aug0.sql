-- Task: Determine, for each status ('strong' or 'soft'), the L1_model(s) that occur most frequently across all models (identified by "name" and "version") and steps, along with the number of times they occur. A model at a specific "step" has a 'strong' status if the maximum "test_score" among non-'Stack' models is less than the 'Stack' model's "test_score". It has a 'soft' status if the maximum "test_score" among non-'Stack' models equals the 'Stack' model's "test_score". Count how many times each "L1_model" is associated with each status across all models and steps. Then, for each status, identify the "L1_model"(s) with the highest occurrence (count).
WITH model_scores AS (
    SELECT 
        "name", 
        "version", 
        "step", 
        MAX(CASE WHEN "model" <> 'Stack' THEN "test_score" END) AS max_test_score,
        MAX(CASE WHEN "model" = 'Stack' THEN "test_score" END) AS stack_score
    FROM STACKING.STACKING.MODEL_SCORE
    GROUP BY "name", "version", "step"
),
combined AS (
    SELECT 
        A."name", 
        A."version", 
        A."step", 
        C."L1_model", 
        CASE 
            WHEN A.max_test_score < A.stack_score THEN 'strong'
            WHEN A.max_test_score = A.stack_score THEN 'soft'
        END AS "status"
    FROM model_scores A
    INNER JOIN STACKING.STACKING.MODEL C 
        ON A."name" = C."name" 
        AND A."version" = C."version"
    WHERE A.max_test_score IS NOT NULL 
      AND A.stack_score IS NOT NULL
),
frequency AS (
    SELECT 
        "L1_model", 
        "status", 
        COUNT(*) AS cnt
    FROM combined
    GROUP BY "L1_model", "status"
),
max_frequency AS (
    SELECT 
        "status", 
        MAX(cnt) AS max_cnt
    FROM frequency
    GROUP BY "status"
)
SELECT 
    f."status",
    f."L1_model",
    m.max_cnt
FROM frequency f
INNER JOIN max_frequency m 
    ON f."status" = m."status" 
    AND f.cnt = m.max_cnt
ORDER BY f."status";