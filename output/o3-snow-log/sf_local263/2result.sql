WITH step_scores AS (               /* score of the Stack model vs best non-Stack model for every step */
    SELECT
        "name",
        "version",
        "step",
        MAX(CASE WHEN "model" = 'Stack'     THEN "test_score" END) AS "stack_score",
        MAX(CASE WHEN "model" <> 'Stack'   THEN "test_score" END) AS "max_non_stack_score"
    FROM STACKING.STACKING."MODEL_SCORE"
    GROUP BY "name","version","step"
),

model_status AS (                   /* overall status of each (name,version) */
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX(CASE WHEN "stack_score" > "max_non_stack_score" THEN 1 ELSE 0 END)=1 THEN 'strong'
            WHEN MAX(CASE WHEN "stack_score" = "max_non_stack_score" THEN 1 ELSE 0 END)=1 THEN 'soft'
        END AS "status"
    FROM step_scores
    WHERE "stack_score" IS NOT NULL
      AND "max_non_stack_score" IS NOT NULL
    GROUP BY "name","version"
    HAVING "status" IS NOT NULL
),

status_l1 AS (                      /* link every step’s L1_model to the status of its (name,version) */
    SELECT 
        m."L1_model",
        ms."status"
    FROM STACKING.STACKING."MODEL" m
    JOIN model_status ms
          ON m."name" = ms."name"
         AND m."version" = ms."version"
),

l1_counts AS (                       /* how many times each L1_model appears in every status */
    SELECT
        "status",
        "L1_model",
        COUNT(*) AS "occurrences"
    FROM status_l1
    GROUP BY "status","L1_model"
),

ranked AS (                          /* pick the L1_model with highest count for each status */
    SELECT
        "status",
        "L1_model",
        "occurrences",
        RANK() OVER (PARTITION BY "status" ORDER BY "occurrences" DESC) AS rnk
    FROM l1_counts
)

SELECT
    "status",
    "L1_model",
    "occurrences"
FROM ranked
WHERE rnk = 1                       /* highest occurrence per status (ties kept) */
ORDER BY "status";