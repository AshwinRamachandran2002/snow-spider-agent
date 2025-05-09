WITH stack_scores AS (
    SELECT 
        name, 
        version, 
        step, 
        test_score AS stack_score
    FROM model_score
    WHERE model = 'Stack'
      AND step IN (1,2,3)
),
nonstack_max AS (
    SELECT 
        name, 
        version, 
        step, 
        MAX(test_score) AS nonstack_max
    FROM model_score
    WHERE model <> 'Stack'
      AND step IN (1,2,3)
    GROUP BY name, version, step
),
qual_steps AS (
    /* steps where Stack beats every non‑Stack model */
    SELECT s.name
    FROM stack_scores s
    LEFT JOIN nonstack_max n
           ON s.name    = n.name
          AND s.version = n.version
          AND s.step    = n.step
    WHERE n.nonstack_max IS NULL OR n.nonstack_max < s.stack_score
),
qual_count AS (
    SELECT name, COUNT(*) AS qual_cnt
    FROM qual_steps
    GROUP BY name
),
solution_count AS (
    SELECT name, COUNT(*) AS sol_cnt
    FROM solution
    GROUP BY name
)
SELECT q.name
FROM qual_count q
JOIN solution_count s ON q.name = s.name
WHERE q.qual_cnt > s.sol_cnt;