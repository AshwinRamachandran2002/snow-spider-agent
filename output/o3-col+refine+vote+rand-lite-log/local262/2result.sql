WITH stack_scores AS (
    SELECT name,
           version,
           step,
           test_score AS stack_test
    FROM   model_score
    WHERE  model LIKE '%Stack%'
      AND  step IN (1,2,3)
),
nonstack_max AS (
    SELECT name,
           version,
           step,
           MAX(test_score) AS max_nonstack_test
    FROM   model_score
    WHERE  model NOT LIKE '%Stack%'
      AND  step IN (1,2,3)
    GROUP  BY name, version, step
),
stack_wins AS (
    SELECT s.name,
           s.version,
           s.step
    FROM   stack_scores s
    JOIN   nonstack_max n
           ON  s.name    = n.name
           AND s.version = n.version
           AND s.step    = n.step
    WHERE  s.stack_test > n.max_nonstack_test
),
stack_win_counts AS (
    SELECT name,
           COUNT(*) AS stack_win_count
    FROM   stack_wins
    GROUP  BY name
),
solution_counts AS (
    SELECT name,
           COUNT(*) AS solution_count
    FROM   solution
    GROUP  BY name
)
SELECT swc.name
FROM   stack_win_counts swc
JOIN   solution_counts sc
       ON swc.name = sc.name
WHERE  swc.stack_win_count > sc.solution_count;