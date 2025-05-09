WITH step_scores AS (
    SELECT 
        "name",
        "version",
        "step",
        MAX(CASE WHEN "model" LIKE '%Stack%'     THEN "test_score" END) AS stack_score,
        MAX(CASE WHEN "model" NOT LIKE '%Stack%' THEN "test_score" END) AS non_stack_best
    FROM "model_score"
    GROUP BY "name", "version", "step"
),
step_status AS (
    SELECT
        "name",
        "version",
        "step",
        CASE
            WHEN stack_score IS NULL           THEN NULL
            WHEN non_stack_best < stack_score  THEN 'strong'
            WHEN non_stack_best = stack_score  THEN 'soft'
        END AS status_step
    FROM step_scores
),
run_status AS (
    SELECT
        "name",
        "version",
        CASE
            WHEN SUM(status_step = 'strong') > 0 THEN 'strong'
            WHEN SUM(status_step = 'soft')   > 0 THEN 'soft'
        END AS status
    FROM step_status
    GROUP BY "name", "version"
),
l1_per_run AS (
    /* use the smallest step for each run so each (name,version) is counted once */
    SELECT 
        rs."name",
        rs."version",
        rs.status,
        m."L1_model"
    FROM run_status AS rs
    JOIN (
        SELECT "name", "version", MIN("step") AS step
        FROM "model"
        GROUP BY "name", "version"
    ) AS first_step
      ON first_step."name"    = rs."name"
     AND first_step."version" = rs."version"
    JOIN "model" AS m
      ON m."name"    = first_step."name"
     AND m."version" = first_step."version"
     AND m."step"    = first_step.step
    WHERE rs.status IS NOT NULL
),
counts AS (
    SELECT 
        status,
        "L1_model",
        COUNT(*) AS occurrences
    FROM l1_per_run
    GROUP BY status, "L1_model"
),
max_counts AS (
    SELECT 
        status,
        MAX(occurrences) AS max_occurrences
    FROM counts
    GROUP BY status
)
SELECT 
    c.status,
    c."L1_model",
    c.occurrences
FROM counts AS c
JOIN max_counts AS m
  ON m.status = c.status
 AND m.max_occurrences = c.occurrences
ORDER BY c.status;