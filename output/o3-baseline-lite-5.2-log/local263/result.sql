WITH step_eval AS (          -- 1.  Best scores (per step) for stack / non‑stack models
    SELECT
        name,
        version,
        step,
        MAX(CASE WHEN model NOT LIKE '%Stack%' THEN test_score END) AS max_nonstack,
        MAX(CASE WHEN model  LIKE '%Stack%' THEN test_score END)    AS stack_score
    FROM model_score
    GROUP BY name, version, step
),

model_status AS (            -- 2.  Status of each (name , version)
    SELECT
        se.name,
        se.version,
        CASE
            WHEN EXISTS (SELECT 1
                         FROM step_eval x
                         WHERE x.name = se.name
                           AND x.version = se.version
                           AND x.stack_score >  x.max_nonstack) THEN 'strong'
            WHEN EXISTS (SELECT 1
                         FROM step_eval x
                         WHERE x.name = se.name
                           AND x.version = se.version
                           AND x.stack_score = x.max_nonstack) THEN 'soft'
        END AS status
    FROM step_eval se
    GROUP BY se.name , se.version
),

l1_per_model AS (            -- 3.  L1_model attached to every (name , version)
    SELECT
        name,
        version,
        MIN(L1_model) AS L1_model          -- identical within a model; MIN() just picks one
    FROM model
    GROUP BY name , version
),

status_l1 AS (               -- 4.  Pair (status , L1_model) for every model that got a status
    SELECT
        ms.status ,
        l1.L1_model
    FROM model_status ms
    JOIN l1_per_model l1 USING (name , version)
    WHERE ms.status IS NOT NULL
),

counts AS (                   -- 5.  How many times each L1_model occurs for every status
    SELECT
        status ,
        L1_model ,
        COUNT(*) AS occurrences
    FROM status_l1
    GROUP BY status , L1_model
),

max_counts AS (               -- 6.  L1_model(s) with the highest count for each status
    SELECT
        c.status ,
        c.L1_model ,
        c.occurrences
    FROM counts c
    JOIN (
        SELECT status , MAX(occurrences) AS max_occ
        FROM counts
        GROUP BY status
    ) m
      ON c.status = m.status
     AND c.occurrences = m.max_occ
)

SELECT
    status ,
    L1_model ,
    occurrences
FROM max_counts
ORDER BY status , L1_model;