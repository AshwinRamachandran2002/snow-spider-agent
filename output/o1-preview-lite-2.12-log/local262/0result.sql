WITH total_occurrences AS (
  SELECT "name", COUNT(*) AS "total_occurrences"
  FROM "solution"
  GROUP BY "name"
), exceed_counts AS (
  SELECT ms."name", COUNT(*) AS "exceed_count"
  FROM (
    SELECT "name", "version", "step", "test_score"
    FROM "model_score"
    WHERE "model" = 'Stack' AND "step" IN (1, 2, 3)
  ) AS ms
  JOIN (
    SELECT "name", "version", "step", MAX("test_score") AS "max_non_stack_score"
    FROM "model_score"
    WHERE "model" <> 'Stack' AND "step" IN (1, 2, 3)
    GROUP BY "name", "version", "step"
  ) AS mns
  ON ms."name" = mns."name" AND ms."version" = mns."version" AND ms."step" = mns."step"
  WHERE ms."test_score" > mns."max_non_stack_score"
  GROUP BY ms."name"
)
SELECT e."name"
FROM exceed_counts e
JOIN total_occurrences t ON e."name" = t."name"
WHERE e."exceed_count" > t."total_occurrences";