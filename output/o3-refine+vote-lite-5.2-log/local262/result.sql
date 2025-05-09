WITH per_step AS (
    SELECT
        name,
        version,
        step,
        MAX(CASE WHEN model LIKE 'Stack%' THEN test_score END)  AS stack_score,
        MAX(CASE WHEN model NOT LIKE 'Stack%' THEN test_score END) AS nonstack_max
    FROM model_score
    WHERE step IN (1,2,3)
    GROUP BY name, version, step
),
qualified AS (          -- steps where Stack beats every non‑Stack model
    SELECT name
    FROM per_step
    WHERE stack_score IS NOT NULL
      AND nonstack_max IS NOT NULL
      AND nonstack_max < stack_score
),
qualified_count AS (
    SELECT name, COUNT(*) AS qcnt
    FROM qualified
    GROUP BY name
),
solution_count AS (
    SELECT name, COUNT(*) AS scnt
    FROM solution
    GROUP BY name
)
SELECT qc.name
FROM qualified_count qc
JOIN solution_count sc ON sc.name = qc.name
WHERE qc.qcnt > sc.scnt;