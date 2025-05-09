WITH model_scores AS (   -- get STACK vs. non-STACK scores per step
    SELECT
        "name" ,
        "version" ,
        "step",
        MAX(CASE WHEN UPPER("model") = 'STACK' THEN "test_score" END)      AS stack_score,
        MAX(CASE WHEN UPPER("model") <> 'STACK' THEN "test_score" END)     AS max_non_stack
    FROM STACKING.STACKING.MODEL_SCORE
    GROUP BY "name", "version", "step"
),

step_status AS (         -- classify each step
    SELECT
        "name",
        "version",
        "step",
        CASE 
            WHEN stack_score > max_non_stack THEN 'strong'
            WHEN stack_score = max_non_stack THEN 'soft'
            ELSE NULL
        END AS step_status
    FROM model_scores
),

model_status AS (        -- derive one status per (name,version)
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX(CASE WHEN step_status = 'strong' THEN 1 ELSE 0 END) = 1 THEN 'strong'
            WHEN MAX(CASE WHEN step_status = 'soft'   THEN 1 ELSE 0 END) = 1 THEN 'soft'
            ELSE NULL
        END AS model_status
    FROM step_status
    GROUP BY "name", "version"
),

model_l1 AS (            -- link every model to its L1_model(s)
    SELECT DISTINCT
        ms.model_status  AS status,
        m."L1_model"
    FROM model_status ms
    JOIN STACKING.STACKING.MODEL m
          ON ms."name" = m."name"
         AND ms."version" = m."version"
    WHERE ms.model_status IN ('strong','soft')
),

l1_counts AS (           -- count occurrences of each L1_model per status
    SELECT
        status,
        "L1_model",
        COUNT(*) AS occurrences
    FROM model_l1
    GROUP BY status, "L1_model"
),

ranked AS (              -- pick the most frequent L1_model per status
    SELECT
        status,
        "L1_model",
        occurrences,
        ROW_NUMBER() OVER (PARTITION BY status
                           ORDER BY occurrences DESC NULLS LAST) AS rn
    FROM l1_counts
)

SELECT
    status,
    "L1_model",
    occurrences
FROM ranked
WHERE rn = 1                -- highest occurrence per status
ORDER BY status;