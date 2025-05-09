WITH stack AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS stack_test_score
    FROM   "model_score"
    WHERE  "model" LIKE '%Stack%'
      AND  "step" IN (1,2,3)
    GROUP BY "name","version","step"
),
nonstack AS (
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS non_stack_best
    FROM   "model_score"
    WHERE  "model" NOT LIKE '%Stack%'
      AND  "step" IN (1,2,3)
    GROUP BY "name","version","step"
),
wins AS (
    SELECT s."name",
           s."version",
           s."step"
    FROM   stack     AS s
    JOIN   nonstack  AS n
           ON s."name" = n."name"
          AND s."version" = n."version"
          AND s."step" = n."step"
    WHERE  s.stack_test_score > n.non_stack_best
),
solution_counts AS (
    SELECT "name",
           COUNT(*) AS nb_solution_rows          -- number of versions for each problem
    FROM   "solution"
    GROUP  BY "name"
)
SELECT   w."name"
FROM     wins AS w
GROUP BY w."name"
HAVING   COUNT(*) > (
            SELECT sc.nb_solution_rows
            FROM   solution_counts AS sc
            WHERE  sc."name" = w."name"
         );