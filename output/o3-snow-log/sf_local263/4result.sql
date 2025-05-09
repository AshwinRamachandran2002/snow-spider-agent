/*-----------------------------------------------------------
Step-by-step
 1) From MODEL_SCORE compute, for every (name,version,step),
    the “Stack” test score and the best non-Stack test score.
 2) Decide the step’s status (strong / soft).
 3) Aggregate the steps to obtain one status per (name,version):
        strong  → at least one strong step
        soft    → otherwise, at least one soft step
 4) Attach the corresponding L1_model (taken from MODEL).
 5) Count how many times each L1_model appears for each status.
 6) For every status return the L1_model with the largest count.
-----------------------------------------------------------*/
WITH step_scores AS (          /* 1 */
    SELECT
        "name",
        "version",
        "step",
        MAX(CASE WHEN UPPER("model") = 'STACK' THEN "test_score" END) AS stack_test_score,
        MAX(CASE WHEN UPPER("model") <> 'STACK' THEN "test_score" END) AS non_stack_max_test_score
    FROM STACKING.STACKING.MODEL_SCORE
    GROUP BY "name", "version", "step"
),
step_status AS (               /* 2 */
    SELECT
        "name",
        "version",
        "step",
        CASE
            WHEN stack_test_score IS NULL                              THEN NULL
            WHEN non_stack_max_test_score IS NULL                      THEN 'strong'
            WHEN stack_test_score  > non_stack_max_test_score          THEN 'strong'
            WHEN stack_test_score  = non_stack_max_test_score          THEN 'soft'
            ELSE NULL
        END AS step_status
    FROM step_scores
),
model_status AS (              /* 3 */
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX(CASE WHEN step_status = 'strong' THEN 1 ELSE 0 END) = 1
                 THEN 'strong'
            WHEN MAX(CASE WHEN step_status = 'soft'   THEN 1 ELSE 0 END) = 1
                 THEN 'soft'
        END AS status
    FROM step_status
    GROUP BY "name", "version"
    HAVING status IS NOT NULL          -- keep only models whose status was determined
),
model_l1 AS (                  /* 4 */
    SELECT DISTINCT
        "name",
        "version",
        "L1_model"
    FROM STACKING.STACKING.MODEL
),
model_status_l1 AS (
    SELECT
        ms."name",
        ms."version",
        ms.status,
        ml."L1_model"
    FROM model_status ms
    JOIN model_l1  ml
          ON  ms."name"    = ml."name"
          AND ms."version" = ml."version"
),
cnt_per_status AS (            /* 5 */
    SELECT
        status,
        "L1_model",
        COUNT(*) AS cnt
    FROM model_status_l1
    GROUP BY status, "L1_model"
),
ranked AS (                     /* 6 */
    SELECT
        status,
        "L1_model",
        cnt,
        ROW_NUMBER() OVER (PARTITION BY status
                           ORDER BY cnt DESC NULLS LAST, "L1_model") AS rn
    FROM cnt_per_status
)
SELECT
    status,
    "L1_model",
    cnt                      -- number of occurrences
FROM ranked
WHERE rn = 1                  -- keep only the most frequent L1_model per status
ORDER BY status;