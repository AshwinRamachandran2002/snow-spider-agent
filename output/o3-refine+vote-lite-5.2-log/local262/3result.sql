WITH stack_vs_non AS (
    SELECT
        ms.name,
        ms.version,
        ms.step,
        MAX(CASE WHEN ms.model LIKE '%Stack%' THEN ms.test_score END) AS stack_score,
        MAX(CASE WHEN ms.model NOT LIKE '%Stack%' THEN ms.test_score END) AS non_stack_max
    FROM model_score AS ms
    WHERE ms.step IN (1, 2, 3)
    GROUP BY ms.name, ms.version, ms.step
),
better_stack_steps AS (
    SELECT
        name,
        version,
        step
    FROM stack_vs_non
    WHERE stack_score IS NOT NULL
      AND non_stack_max IS NOT NULL
      AND non_stack_max < stack_score          -- “Stack” beats every non‑stack model
),
cnt_better AS (
    SELECT
        name,
        COUNT(*) AS better_cnt                 -- number of (version, step) occurrences
    FROM better_stack_steps
    GROUP BY name
),
cnt_solution AS (
    SELECT
        name,
        COUNT(*) AS sol_cnt                    -- total rows in solution table
    FROM solution
    GROUP BY name
)
SELECT
    b.name
FROM cnt_better AS b
JOIN cnt_solution AS s
  ON b.name = s.name
WHERE b.better_cnt > s.sol_cnt;