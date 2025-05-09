SELECT sc."name" AS "Problem_Name"
FROM (
  SELECT s."name", COUNT(*) AS "stack_better_count"
  FROM (
    SELECT "name", "version", "step", "test_score"
    FROM "model_score"
    WHERE "model" = 'Stack'
  ) s
  JOIN (
    SELECT "name", "version", "step", MAX("test_score") AS "max_non_stack_score"
    FROM "model_score"
    WHERE "model" <> 'Stack'
    GROUP BY "name", "version", "step"
  ) ns
  ON s."name" = ns."name" AND s."version" = ns."version" AND s."step" = ns."step"
  WHERE s."test_score" > ns."max_non_stack_score"
  GROUP BY s."name"
) sc
JOIN (
  SELECT "name", COUNT(*) AS "total_occurrences"
  FROM "solution"
  GROUP BY "name"
) sol
ON sc."name" = sol."name"
WHERE sc."stack_better_count" > sol."total_occurrences";