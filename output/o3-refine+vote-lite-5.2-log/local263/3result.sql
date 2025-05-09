WITH non_stack_max AS (
    SELECT name,
           version,
           step,
           MAX(test_score) AS max_non_stack
    FROM model_score
    WHERE LOWER(model) NOT LIKE '%stack%'
    GROUP BY name, version, step
),
stack_scores AS (
    SELECT name,
           version,
           step,
           test_score AS stack_score
    FROM model_score
    WHERE LOWER(model) LIKE '%stack%'
),
step_comparison AS (
    SELECT n.name,
           n.version,
           n.step,
           CASE
               WHEN s.stack_score > n.max_non_stack THEN 'strong_step'
               WHEN s.stack_score = n.max_non_stack THEN 'soft_step'
               ELSE 'other'
           END AS step_status
    FROM non_stack_max n
    JOIN stack_scores s
      ON n.name = s.name
     AND n.version = s.version
     AND n.step = s.step
),
model_status AS (
    SELECT name,
           version,
           CASE
               WHEN SUM(CASE WHEN step_status = 'strong_step' THEN 1 ELSE 0 END) > 0
                    THEN 'strong'
               WHEN SUM(CASE WHEN step_status = 'soft_step'   THEN 1 ELSE 0 END) > 0
                    THEN 'soft'
           END AS status
    FROM step_comparison
    GROUP BY name, version
    HAVING status IS NOT NULL
),
model_l1 AS (
    -- assuming each (name, version) has only one distinct L1_model
    SELECT name,
           version,
           MIN(L1_model) AS L1_model
    FROM model
    GROUP BY name, version
),
status_l1_counts AS (
    SELECT ms.status,
           ml.L1_model,
           COUNT(*) AS cnt
    FROM model_status ms
    JOIN model_l1   ml USING (name, version)
    GROUP BY ms.status, ml.L1_model
),
ranked AS (
    SELECT status,
           L1_model,
           cnt,
           RANK() OVER (PARTITION BY status ORDER BY cnt DESC) AS rnk
    FROM status_l1_counts
)
SELECT status,
       L1_model,
       cnt AS occurrence
FROM ranked
WHERE rnk = 1
ORDER BY status;