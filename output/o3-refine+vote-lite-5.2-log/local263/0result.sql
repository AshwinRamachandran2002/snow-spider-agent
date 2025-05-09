WITH step_scores AS (          -- get Stack and non‑Stack best test scores per step
    SELECT  name,
            version,
            step,
            MAX(CASE WHEN model = 'Stack' THEN test_score END)              AS stack_score,
            MAX(CASE WHEN model <> 'Stack' THEN test_score END)             AS non_stack_score
    FROM    model_score
    GROUP BY name, version, step
),
step_flags AS (                 -- flag the step as strong / soft
    SELECT  name,
            version,
            CASE                                                   -- strong if Stack strictly better
                 WHEN stack_score > COALESCE(non_stack_score, -1e9) THEN 1
                 ELSE 0
            END                                                   AS strong_flag,
            CASE                                                   -- soft if Stack ties the best
                 WHEN stack_score = non_stack_score 
                      AND stack_score IS NOT NULL                  THEN 1
                 ELSE 0
            END                                                   AS soft_flag
    FROM    step_scores
),
model_status AS (               -- decide the global status of each (name,version)
    SELECT  name,
            version,
            CASE WHEN MAX(strong_flag) = 1 THEN 'strong'
                 WHEN MAX(soft_flag)   = 1 THEN 'soft'
            END                                                   AS status
    FROM    step_flags
    GROUP BY name, version
    HAVING status IS NOT NULL
),
l1_occurrences AS (             -- count L1_model appearances per status
    SELECT  ms.status,
            m.L1_model,
            COUNT(*)                                              AS cnt
    FROM    model            AS m
    JOIN    model_status     AS ms
           ON m.name = ms.name
          AND m.version = ms.version
    GROUP BY ms.status, m.L1_model
),
ranked AS (                     -- keep the most frequent L1_model(s) for each status
    SELECT  status,
            L1_model,
            cnt,
            RANK() OVER (PARTITION BY status ORDER BY cnt DESC)   AS rnk
    FROM    l1_occurrences
)
SELECT  status,
        L1_model,
        cnt
FROM    ranked
WHERE   rnk = 1
ORDER BY status, L1_model;