WITH stack_scores AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS stack_test
    FROM   "model_score"
    WHERE  LOWER("model") LIKE '%stack%'
    GROUP  BY "name","version","step"
),
non_stack_scores AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS non_stack_test
    FROM   "model_score"
    WHERE  LOWER("model") NOT LIKE '%stack%'
    GROUP  BY "name","version","step"
),
better_steps AS (
    SELECT n."name"
    FROM   non_stack_scores n
    JOIN   stack_scores     s
           USING ("name","version","step")
    WHERE  n."step" IN (1,2,3)
      AND  n.non_stack_test < s.stack_test
),
cnt_better AS (
    SELECT "name",
           COUNT(*) AS nb_better_steps
    FROM   better_steps
    GROUP  BY "name"
),
cnt_solution AS (
    SELECT "name",
           COUNT(*) AS nb_in_solution
    FROM   "solution"
    GROUP  BY "name"
)
SELECT DISTINCT cb."name"
FROM   cnt_better   cb
JOIN   cnt_solution cs USING ("name")
WHERE  cb.nb_better_steps > cs.nb_in_solution;