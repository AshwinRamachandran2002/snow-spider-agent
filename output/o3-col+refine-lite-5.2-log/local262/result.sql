WITH stack_scores AS (
    SELECT "name",
           "version",
           "step",
           "test_score"
    FROM "model_score"
    WHERE LOWER("model") LIKE '%stack%'
      AND "step" IN (1,2,3)
),
max_nonstack AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS max_nonstack_test
    FROM "model_score"
    WHERE LOWER("model") NOT LIKE '%stack%'
      AND "step" IN (1,2,3)
    GROUP BY "name", "version", "step"
),
stack_better AS (
    SELECT s."name",
           s."version",
           s."step"
    FROM stack_scores  s
    JOIN max_nonstack m
      ON s."name"    = m."name"
     AND s."version" = m."version"
     AND s."step"    = m."step"
    WHERE s."test_score" > m.max_nonstack_test
),
stack_better_count AS (
    SELECT "name",
           COUNT(*) AS nb_stack_better
    FROM stack_better
    GROUP BY "name"
),
solution_count AS (
    SELECT "name",
           COUNT(*) AS nb_solution
    FROM "solution"
    GROUP BY "name"
)
SELECT sbc."name"
FROM stack_better_count sbc
JOIN solution_count  sc
  ON sbc."name" = sc."name"
WHERE sbc.nb_stack_better > sc.nb_solution;