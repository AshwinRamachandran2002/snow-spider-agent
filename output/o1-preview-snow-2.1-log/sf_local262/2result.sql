WITH model_comparisons AS (
  SELECT t."model" AS "model_name",
         SUM(CASE WHEN t."test_score" < s."test_score" THEN 1 ELSE 0 END) AS worse_than_stack_count,
         COUNT(*) AS total_evaluations
  FROM "STACKING"."STACKING"."MODEL_SCORE" t
  INNER JOIN "STACKING"."STACKING"."MODEL_SCORE" s
    ON t."name" = s."name" AND t."version" = s."version" AND t."step" = s."step"
  WHERE s."model" = 'Stack' AND t."model" <> 'Stack'
  GROUP BY t."model"
)
SELECT "model_name"
FROM model_comparisons
WHERE worse_than_stack_count > total_evaluations / 2;