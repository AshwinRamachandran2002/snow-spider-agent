WITH stack_scores AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS stack_test
    FROM   "model_score"
    WHERE  "model" = 'Stack'
      AND  "step" IN (1,2,3)
    GROUP BY "name","version","step"
),
non_stack_scores AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS non_stack_best
    FROM   "model_score"
    WHERE  "model" <> 'Stack'
      AND  "step" IN (1,2,3)
    GROUP BY "name","version","step"
),
stack_wins AS (
    SELECT s."name"
    FROM   stack_scores     AS s
    JOIN   non_stack_scores AS n
      ON   s."name"    = n."name"
     AND   s."version" = n."version"
     AND   s."step"    = n."step"
    WHERE  s.stack_test > n.non_stack_best
),
cnt_stack_wins AS (
    SELECT "name",
           COUNT(*) AS cnt_stack_wins
    FROM   stack_wins
    GROUP BY "name"
),
cnt_solution AS (
    SELECT "name",
           COUNT(*) AS cnt_in_solution
    FROM   "solution"
    GROUP BY "name"
)
SELECT csw."name" AS problem
FROM   cnt_stack_wins csw
JOIN   cnt_solution  csol
  ON   csw."name" = csol."name"
WHERE  csw.cnt_stack_wins > csol.cnt_in_solution
ORDER BY problem;