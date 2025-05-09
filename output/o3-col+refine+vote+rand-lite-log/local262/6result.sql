WITH per_step AS (
    SELECT
        name,
        version,
        step,
        MAX(CASE WHEN model LIKE '%Stack%'      THEN test_score END) AS stack_score,
        MAX(CASE WHEN model NOT LIKE '%Stack%'  THEN test_score END) AS nonstack_max
    FROM model_score
    WHERE step IN (1,2,3)                  -- only steps 1-3
    GROUP BY name, version, step
),
better_steps AS (                           -- “Stack” beats best non-“Stack”
    SELECT name, version, step
    FROM per_step
    WHERE stack_score IS NOT NULL
      AND nonstack_max IS NOT NULL
      AND stack_score > nonstack_max
),
stack_count AS (                            -- count such steps per problem
    SELECT name,
           COUNT(*) AS better_stack_steps
    FROM better_steps
    GROUP BY name
),
solution_count AS (                         -- count rows per problem in solution
    SELECT name,
           COUNT(*) AS solution_rows
    FROM solution
    GROUP BY name
)
SELECT sc.name
FROM stack_count   sc
JOIN solution_count s ON sc.name = s.name
WHERE sc.better_stack_steps > s.solution_rows;