WITH step_scores AS (                 -- 1. best non‑stack vs. stack on every step
    SELECT
        ms.name,
        ms.version,
        ms.step,
        MAX(CASE WHEN ms.model LIKE 'Stack%'     THEN ms.test_score END) AS stack_test,
        MAX(CASE WHEN ms.model NOT LIKE 'Stack%' THEN ms.test_score END) AS max_non_stack
    FROM model_score AS ms
    GROUP BY ms.name, ms.version, ms.step
    HAVING stack_test IS NOT NULL              -- keep only steps having both kinds of models
       AND max_non_stack IS NOT NULL
),
model_status AS (                     -- 2. strong / soft status for each (name,version)
    SELECT
        ss.name,
        ss.version,
        CASE
            WHEN SUM(CASE WHEN ss.stack_test > ss.max_non_stack THEN 1 ELSE 0 END) > 0
                 THEN 'strong'
            WHEN SUM(CASE WHEN ss.stack_test = ss.max_non_stack THEN 1 ELSE 0 END) > 0
                 THEN 'soft'
        END AS status
    FROM step_scores AS ss
    GROUP BY ss.name, ss.version
    HAVING status IS NOT NULL
),
l1_mode AS (                          -- 3. most common L1_model for each (name,version)
    SELECT
        m.name,
        m.version,
        m.L1_model,
        COUNT(*)                               AS cnt,
        ROW_NUMBER() OVER (PARTITION BY m.name, m.version
                           ORDER BY COUNT(*) DESC, m.L1_model) AS rn
    FROM model AS m
    GROUP BY m.name, m.version, m.L1_model
),
model_l1 AS (                         -- 4. keep the single chosen L1_model per model
    SELECT name, version, L1_model
    FROM   l1_mode
    WHERE  rn = 1
),
status_l1 AS (                        -- 5. attach status to its L1_model
    SELECT
        ms.status,
        ml.L1_model
    FROM model_status AS ms
    JOIN model_l1    AS ml
      ON ms.name = ml.name
     AND ms.version = ml.version
),
status_counts AS (                    -- 6. how many times each L1_model occurs per status
    SELECT
        status,
        L1_model,
        COUNT(*)                                     AS occurrences,
        ROW_NUMBER() OVER (PARTITION BY status
                           ORDER BY COUNT(*) DESC, L1_model) AS rn
    FROM status_l1
    GROUP BY status, L1_model
)
SELECT
    status,
    L1_model,
    occurrences
FROM status_counts
WHERE rn = 1                          -- 7. most frequent L1_model for every status
ORDER BY status;