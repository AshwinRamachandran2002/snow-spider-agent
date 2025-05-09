WITH total_evaluations AS (
  SELECT "model", COUNT(*) AS "total_evaluations"
  FROM STACKING.STACKING.MODEL_SCORE
  WHERE "model" <> 'Stack'
  GROUP BY "model"
),
worse_counts AS (
  SELECT t1."model", COUNT(*) AS "worse_count"
  FROM STACKING.STACKING.MODEL_SCORE t1
  JOIN STACKING.STACKING.MODEL_SCORE t2
    ON t1."name" = t2."name"
    AND t1."version" = t2."version"
    AND t1."step" = t2."step"
  WHERE t1."model" <> 'Stack'
    AND t2."model" = 'Stack'
    AND t1."test_score" < t2."test_score"
  GROUP BY t1."model"
)
SELECT t."model" AS "model_name"
FROM total_evaluations t
JOIN worse_counts w ON t."model" = w."model"
WHERE w."worse_count" > (t."total_evaluations" / 2);