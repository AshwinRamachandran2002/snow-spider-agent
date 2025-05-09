WITH non_stack_max AS (
    SELECT name,
           version,
           step,
           MAX(test_score) AS max_non_stack_test
    FROM   model_score
    WHERE  model <> 'Stack'
      AND  step IN (1,2,3)
    GROUP BY name, version, step
),
stack_wins AS (
    SELECT ms.name,
           ms.version,
           ms.step
    FROM   model_score AS ms
    JOIN   non_stack_max AS ns
           ON  ms.name    = ns.name
           AND ms.version = ns.version
           AND ms.step    = ns.step
    WHERE  ms.model = 'Stack'
      AND  ms.test_score > ns.max_non_stack_test
),
stack_win_count AS (
    SELECT name,
           COUNT(*) AS nb_stack_better
    FROM   stack_wins
    GROUP BY name
),
solution_count AS (
    SELECT name,
           COUNT(*) AS nb_in_solution
    FROM   solution
    GROUP BY name
)
SELECT swc.name
FROM   stack_win_count AS swc
JOIN   solution_count AS sc
       ON swc.name = sc.name
WHERE  swc.nb_stack_better > sc.nb_in_solution;