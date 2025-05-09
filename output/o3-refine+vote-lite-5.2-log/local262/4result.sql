WITH step_scores AS (
    SELECT
        name,
        version,
        step,
        MAX(CASE WHEN model NOT LIKE '%Stack%' THEN test_score END)  AS max_non_stack,
        MAX(CASE WHEN model LIKE '%Stack%'  THEN test_score END)     AS stack_score
    FROM model_score
    WHERE step IN (1,2,3)
    GROUP BY name, version, step
),
better_stack AS (
    SELECT name
    FROM step_scores
    WHERE stack_score IS NOT NULL
      AND max_non_stack IS NOT NULL
      AND stack_score > max_non_stack
),
better_cnt AS (
    SELECT name, COUNT(*) AS cnt_better
    FROM better_stack
    GROUP BY name
),
solution_cnt AS (
    SELECT name, COUNT(*) AS cnt_solution
    FROM solution
    GROUP BY name
)
SELECT b.name
FROM better_cnt b
JOIN solution_cnt s
  ON b.name = s.name
WHERE b.cnt_better > s.cnt_solution;