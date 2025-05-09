/* 1) get, for every (name,version,step), the stack score and the best non-stack score            */
WITH step_scores AS (
    SELECT
        "name",
        "version",
        "step",
        MAX(CASE WHEN "model" = 'Stack' THEN "test_score" END)                         AS "stack_score",
        MAX(CASE WHEN "model" <> 'Stack' THEN "test_score" END)                        AS "best_non_stack_score"
    FROM STACKING.STACKING.MODEL_SCORE
    GROUP BY "name", "version", "step"
),

/* 2) decide, for every (name,version), whether it is “strong” or “soft”                      */
model_status AS (
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX(CASE WHEN "stack_score" > "best_non_stack_score" THEN 1 END) = 1 THEN 'strong'
            WHEN MAX(CASE WHEN "stack_score" = "best_non_stack_score" THEN 1 END) = 1 THEN 'soft'
        END                                                                                   AS "status"
    FROM step_scores
    GROUP BY "name", "version"
    HAVING "status" IS NOT NULL                              -- keep only models we could classify
),

/* 3) list the L1_model attached to every (name,version)                                       */
model_l1 AS (
    SELECT DISTINCT
        "name",
        "version",
        "L1_model"
    FROM STACKING.STACKING.MODEL
),

/* 4) connect status with L1_model and count occurrences                                       */
counts AS (
    SELECT
        s."status",
        l."L1_model",
        COUNT(*) AS "nb_occurrences"
    FROM model_status      s
    JOIN model_l1          l
      ON s."name"    = l."name"
     AND s."version" = l."version"
    GROUP BY s."status", l."L1_model"
),

/* 5) pick, for each status, the L1_model that appears the most                                */
ranked AS (
    SELECT
        "status",
        "L1_model",
        "nb_occurrences",
        ROW_NUMBER() OVER (PARTITION BY "status"
                           ORDER BY "nb_occurrences" DESC NULLS LAST) AS rnk
    FROM counts
)

SELECT
    "status",
    "L1_model",
    "nb_occurrences"
FROM ranked
WHERE rnk = 1
ORDER BY "status";