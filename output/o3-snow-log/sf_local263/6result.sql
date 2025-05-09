WITH stack_vs_non AS (   -- best Stack score and best non-Stack score per step
    SELECT
        ms."name",
        ms."version",
        ms."step",
        MAX(CASE WHEN ms."model" = 'Stack' THEN ms."test_score" END)                              AS "stack_score",
        MAX(CASE WHEN ms."model" <> 'Stack' OR ms."model" IS NULL THEN ms."test_score" END)       AS "best_non_stack"
    FROM STACKING.STACKING."MODEL_SCORE" ms
    GROUP BY ms."name", ms."version", ms."step"
),
status_per_model AS (    -- classify every (name , version) as strong / soft
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX( IFF("best_non_stack" < "stack_score", 1, 0) ) = 1 THEN 'strong'
            WHEN MAX( IFF("best_non_stack" = "stack_score", 1, 0) ) = 1 THEN 'soft'
        END AS "status"
    FROM stack_vs_non
    WHERE "stack_score" IS NOT NULL
    GROUP BY "name", "version"
    HAVING "status" IS NOT NULL
),
model_distinct AS (      -- one row per model (name , version)
    SELECT DISTINCT
        "name",
        "version",
        "L1_model"
    FROM STACKING.STACKING."MODEL"
),
l1_counts AS (           -- occurrences of every L1_model inside each status
    SELECT
        spm."status",
        md."L1_model",
        COUNT(*) AS "occurrences"
    FROM status_per_model spm
    JOIN model_distinct   md
      ON md."name"    = spm."name"
     AND md."version" = spm."version"
    GROUP BY spm."status", md."L1_model"
),
ranked AS (              -- rank L1_models by frequency per status
    SELECT
        "status",
        "L1_model",
        "occurrences",
        RANK() OVER (PARTITION BY "status" ORDER BY "occurrences" DESC) AS "rnk"
    FROM l1_counts
)
SELECT                    -- most frequent L1_model for each status
    "status",
    "L1_model",
    "occurrences"
FROM ranked
WHERE "rnk" = 1
ORDER BY "status";