WITH step_scores AS (                 -- best non‑Stack vs. Stack score per step
    SELECT  "name",
            "version",
            "step",
            MAX(CASE WHEN "model" <> 'Stack' THEN "test_score" END) AS max_non_stack,
            MAX(CASE WHEN "model"  = 'Stack' THEN "test_score" END) AS stack_score
    FROM    "model_score"
    GROUP BY "name", "version", "step"
),
step_status AS (                      -- label each step
    SELECT  "name",
            "version",
            "step",
            CASE
                WHEN stack_score > max_non_stack THEN 'strong'
                WHEN stack_score = max_non_stack THEN 'soft'
            END AS step_status
    FROM    step_scores
),
model_status AS (                     -- label each (name,version) experiment
    SELECT  "name",
            "version",
            CASE
                WHEN SUM(CASE WHEN step_status = 'strong' THEN 1 END) > 0 THEN 'strong'
                WHEN SUM(CASE WHEN step_status = 'soft'   THEN 1 END) > 0 THEN 'soft'
            END AS status
    FROM    step_status
    GROUP BY "name", "version"
    HAVING  status IS NOT NULL
),
l1_status AS (                        -- attach the experiment’s L1_model
    SELECT  m."L1_model",
            ms.status
    FROM    model_status AS ms
    JOIN   (SELECT DISTINCT "name", "version", "L1_model" FROM "model") AS m
           ON ms."name"    = m."name"
          AND ms."version" = m."version"
),
counts AS (                           -- occurrences of each (status, L1_model)
    SELECT  status,
            "L1_model",
            COUNT(*) AS occurrences
    FROM    l1_status
    GROUP BY status, "L1_model"
),
max_counts AS (                       -- highest occurrence per status
    SELECT  status,
            MAX(occurrences) AS max_occ
    FROM    counts
    GROUP BY status
)
SELECT  c.status,
        c."L1_model",
        c.occurrences
FROM    counts     AS c
JOIN    max_counts AS m
      ON c.status = m.status
     AND c.occurrences = m.max_occ
ORDER BY c.status, c."L1_model";