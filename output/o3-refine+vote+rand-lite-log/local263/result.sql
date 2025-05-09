WITH step_scores AS (
    SELECT 
        "name",
        "version",
        "step",
        MAX(CASE WHEN "model" NOT LIKE '%Stack%' THEN "test_score" END) AS max_non_stack,
        MAX(CASE WHEN "model"     LIKE '%Stack%' THEN "test_score" END) AS stack_score
    FROM "model_score"
    GROUP BY "name","version","step"
),
step_status AS (
    SELECT
        "name",
        "version",
        "step",
        CASE
            WHEN stack_score IS NOT NULL 
                 AND max_non_stack IS NOT NULL
                 AND stack_score > max_non_stack THEN 'strong'
            WHEN stack_score IS NOT NULL 
                 AND max_non_stack IS NOT NULL
                 AND stack_score = max_non_stack THEN 'soft'
        END AS step_state
    FROM step_scores
),
model_status AS (
    SELECT
        "name",
        "version",
        CASE
            WHEN SUM(CASE WHEN step_state='strong' THEN 1 END) > 0 THEN 'strong'
            WHEN SUM(CASE WHEN step_state='soft'   THEN 1 END) > 0 THEN 'soft'
        END AS status
    FROM step_status
    GROUP BY "name","version"
    HAVING status IS NOT NULL
),
l1_counts AS (
    SELECT
        m."name",
        m."version",
        m."L1_model",
        COUNT(*) AS cnt
    FROM "model" m
    JOIN model_status s
      ON m."name" = s."name" AND m."version" = s."version"
    GROUP BY m."name", m."version", m."L1_model"
),
model_top_l1 AS (
    /* most frequent L1_model for each (name,version) */
    SELECT
        c."name",
        c."version",
        c."L1_model",
        s.status,
        c.cnt
    FROM l1_counts c
    JOIN (
        SELECT "name","version", MAX(cnt) AS mc
        FROM l1_counts
        GROUP BY "name","version"
    ) mx
      ON c."name" = mx."name"
     AND c."version" = mx."version"
     AND c.cnt = mx.mc
    JOIN model_status s
      ON c."name" = s."name" AND c."version" = s."version"
),
l1_status_totals AS (
    SELECT
        status,
        "L1_model",
        COUNT(*) AS occurrences
    FROM model_top_l1
    GROUP BY status, "L1_model"
),
result AS (
    SELECT
        status,
        /* if several tie, pick alphabetically first */
        MIN("L1_model") AS L1_model,
        MAX(occurrences) AS occurrences
    FROM l1_status_totals
    GROUP BY status
)
SELECT status,
       L1_model,
       occurrences
FROM result
ORDER BY status;