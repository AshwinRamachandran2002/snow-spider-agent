WITH
-- Stack and best non-Stack test scores for steps 1-3
stack_vs_nonstack AS (
    SELECT  s.name,
            s.version,
            s.step,
            s.test_score        AS stack_test_score,
            n.max_nonstack_test_score
    FROM   (SELECT name, version, step, test_score
            FROM   model_score
            WHERE  lower(model) LIKE '%stack%') AS s
    JOIN   (SELECT name, version, step,
                   MAX(test_score) AS max_nonstack_test_score
            FROM   model_score
            WHERE  lower(model) NOT LIKE '%stack%'
            GROUP  BY name, version, step) AS n
      ON  s.name    = n.name
      AND s.version = n.version
      AND s.step    = n.step
    WHERE  s.step IN (1,2,3)
),

-- Keep only the (name,version,step) where Stack beats every non-Stack model
stack_better AS (
    SELECT name
    FROM   stack_vs_nonstack
    WHERE  stack_test_score > max_nonstack_test_score
),

-- Count how many times that happens for each problem
cnt_stack_better AS (
    SELECT name,
           COUNT(*) AS nb_stack_better
    FROM   stack_better
    GROUP  BY name
),

-- Count how many rows each problem has in the solution table
cnt_solution AS (
    SELECT name,
           COUNT(*) AS nb_solution_rows
    FROM   solution
    GROUP  BY name
)

-- Final answer: problems where Stack-better count exceeds solution-row count
SELECT csb.name
FROM   cnt_stack_better  AS csb
JOIN   cnt_solution      AS csol
  ON   csb.name = csol.name
WHERE  csb.nb_stack_better > csol.nb_solution_rows;