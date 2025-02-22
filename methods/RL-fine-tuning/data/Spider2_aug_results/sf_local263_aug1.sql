-- Task: For each model (specified by "name", "version", and "step"), compute the maximum test score among non-'Stack' models and the maximum test score among 'Stack' models. Limit the results to 100 rows.
SELECT 
    "name", 
    "version", 
    "step", 
    MAX(CASE WHEN "model" <> 'Stack' THEN "test_score" END) AS "max_test_score",
    MAX(CASE WHEN "model" = 'Stack' THEN "test_score" END) AS "stack_score"
FROM STACKING.STACKING.MODEL_SCORE
GROUP BY "name", "version", "step"
LIMIT 100;