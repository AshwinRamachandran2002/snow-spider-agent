WITH step_scores AS (    -- score of the “Stack” model vs best non‑Stack for every (name,version,step)
    SELECT 
        name,
        version,
        step,
        MAX(CASE WHEN model LIKE '%Stack%' THEN test_score END)     AS stack_score,
        MAX(CASE WHEN model NOT LIKE '%Stack%' THEN test_score END) AS non_stack_max
    FROM model_score
    GROUP BY name, version, step
),

step_status AS (         -- classify every individual step
    SELECT
        name,
        version,
        CASE
            WHEN stack_score IS NOT NULL AND stack_score >  non_stack_max THEN 'strong'
            WHEN stack_score IS NOT NULL AND stack_score =  non_stack_max THEN 'soft'
        END AS step_status
    FROM step_scores
),

model_status AS (        -- overall status for each (name,version)
    SELECT
        name,
        version,
        CASE
            WHEN SUM(CASE WHEN step_status = 'strong' THEN 1 END) > 0 THEN 'strong'
            WHEN SUM(CASE WHEN step_status = 'soft'   THEN 1 END) > 0 THEN 'soft'
        END AS status
    FROM step_status
    GROUP BY name, version
),

model_l1 AS (            -- one line per (name,version) and its L1_model
    SELECT DISTINCT
        name,
        version,
        L1_model
    FROM model
),

status_l1_count AS (     -- how many times every L1_model appears for each status
    SELECT
        ml.L1_model,
        ms.status,
        COUNT(DISTINCT ml.name || '|' || ml.version) AS cnt
    FROM model_l1   ml
    JOIN model_status ms
          ON ms.name = ml.name
         AND ms.version = ml.version
    WHERE ms.status IS NOT NULL
    GROUP BY ms.status, ml.L1_model
),

ranked AS (              -- pick the L1_model(s) with the highest count per status
    SELECT
        *,
        RANK() OVER (PARTITION BY status ORDER BY cnt DESC) AS rnk
    FROM status_l1_count
)

SELECT
    status            AS model_status,
    L1_model,
    cnt               AS occurrences
FROM ranked
WHERE rnk = 1          -- highest count within each status
ORDER BY status;