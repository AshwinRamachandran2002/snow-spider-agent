WITH step_scores AS (          -- 1. best Stack vs. best non‑Stack for every (name,version,step)
    SELECT
        name,
        version,
        step,
        MAX(CASE WHEN model LIKE 'Stack%'     THEN test_score END) AS stack_score,
        MAX(CASE WHEN model NOT LIKE 'Stack%' THEN test_score END) AS max_non_stack
    FROM model_score
    GROUP BY name, version, step
),
step_status AS (               -- 2. classify each step
    SELECT
        name,
        version,
        step,
        CASE
            WHEN stack_score IS NOT NULL
                 AND max_non_stack IS NOT NULL
                 AND stack_score > max_non_stack  THEN 'strong'
            WHEN stack_score IS NOT NULL
                 AND max_non_stack IS NOT NULL
                 AND stack_score = max_non_stack THEN 'soft'
        END AS step_status
    FROM step_scores
),
model_status AS (              -- 3. status for the whole (name,version)
    SELECT
        name,
        version,
        CASE
            WHEN SUM(step_status = 'strong') > 0 THEN 'strong'
            WHEN SUM(step_status = 'soft')   > 0 THEN 'soft'
        END AS status
    FROM step_status
    GROUP BY name, version
    HAVING status IS NOT NULL
),
model_major_l1 AS (            -- 4. most frequent L1_model for every (name,version)
    SELECT name, version, L1_model
    FROM (
        SELECT
            m.name,
            m.version,
            m.L1_model,
            COUNT(*)                                        AS cnt,
            ROW_NUMBER() OVER (PARTITION BY m.name, m.version
                                ORDER BY COUNT(*) DESC, L1_model) AS rn
        FROM model AS m
        GROUP BY m.name, m.version, m.L1_model
    )
    WHERE rn = 1
),
status_l1_counts AS (          -- 5. how often each L1_model appears under each status
    SELECT
        ms.status,
        ml.L1_model,
        COUNT(*) AS occurrences
    FROM model_status     AS ms
    JOIN model_major_l1   AS ml USING (name, version)
    GROUP BY ms.status, ml.L1_model
),
ranked AS (                    -- 6. pick the top L1_model for every status
    SELECT
        status,
        L1_model,
        occurrences,
        ROW_NUMBER() OVER (PARTITION BY status
                           ORDER BY occurrences DESC, L1_model) AS rn
    FROM status_l1_counts
)
SELECT
    status,
    L1_model,
    occurrences
FROM ranked
WHERE rn = 1;