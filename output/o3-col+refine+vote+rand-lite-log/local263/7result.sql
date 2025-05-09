WITH non_stack AS (                -- best non-Stack score for every step
    SELECT "name",
           "version",
           "step",
           MAX("test_score") AS max_non_stack
    FROM   "model_score"
    WHERE  "model" NOT LIKE '%Stack%'
    GROUP  BY "name","version","step"
),
stack AS (                          -- Stack score for every step
    SELECT "name",
           "version",
           "step",
           "test_score" AS stack_score
    FROM   "model_score"
    WHERE  "model" LIKE '%Stack%'
),
step_status AS (                    -- label each (name,version,step)
    SELECT ns."name",
           ns."version",
           ns."step",
           CASE
               WHEN st.stack_score > ns.max_non_stack THEN 'strong'
               WHEN st.stack_score = ns.max_non_stack THEN 'soft'
           END AS status
    FROM   non_stack ns
    JOIN   stack     st
           ON st."name"    = ns."name"
          AND st."version" = ns."version"
          AND st."step"    = ns."step"
),
model_status AS (                   -- one status per (name,version)
    SELECT "name",
           "version",
           CASE
               WHEN SUM(CASE WHEN status = 'strong' THEN 1 END) > 0
               THEN 'strong'
               ELSE 'soft'
           END AS status
    FROM   step_status
    GROUP  BY "name","version"
),
l1 AS (                              -- L1_model attached to each (name,version)
    SELECT "name",
           "version",
           MAX("L1_model") AS L1_model
    FROM   "model"
    GROUP  BY "name","version"
),
totals AS (                          -- count appearances of every L1_model per status
    SELECT l1.L1_model,
           ms.status,
           COUNT(*) AS occurrences
    FROM   l1
    JOIN   model_status ms
           ON ms."name"    = l1."name"
          AND ms."version" = l1."version"
    GROUP  BY l1.L1_model, ms.status
),
ranked AS (                          -- keep the most frequent per status
    SELECT *,
           RANK() OVER (PARTITION BY status
                         ORDER BY occurrences DESC) AS rnk
    FROM   totals
)
SELECT status,
       L1_model,
       occurrences
FROM   ranked
WHERE  rnk = 1
ORDER  BY status;