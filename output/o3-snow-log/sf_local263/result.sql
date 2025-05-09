/*--------------------------------------------------------------------
   1.  For every (name , version , step) compute :
          – test score of the row whose "model" = 'Stack'
          – best test score among rows whose "model" <> 'Stack'
--------------------------------------------------------------------*/
WITH step_scores AS (
    SELECT
        "name",
        "version",
        "step",
        MAX(CASE WHEN "model" = 'Stack'          THEN "test_score" END) AS stack_score,
        MAX(CASE WHEN "model" <> 'Stack'         THEN "test_score" END) AS best_non_stack_score
    FROM STACKING.STACKING.MODEL_SCORE
    GROUP BY "name", "version", "step"
),

/*--------------------------------------------------------------------
   2.  Status of every (name , version)
          – strong : at least one step where Stack score  > best non-Stack
          – soft   : (not strong) and at least one step where Stack score = best non-Stack
--------------------------------------------------------------------*/
model_status AS (
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX( CASE
                        WHEN COALESCE(stack_score , -1e9) > COALESCE(best_non_stack_score , -1e9)
                        THEN 1 ELSE 0
                      END ) = 1
                 THEN 'strong'

            WHEN MAX( CASE
                        WHEN stack_score = best_non_stack_score
                             AND best_non_stack_score IS NOT NULL
                        THEN 1 ELSE 0
                      END ) = 1
                 THEN 'soft'
        END AS status
    FROM step_scores
    GROUP BY "name", "version"
),

/*--------------------------------------------------------------------
   3.  For every (name , version) find the L1_model that
       appears most often across its steps in STACKING.STACKING.MODEL
--------------------------------------------------------------------*/
model_l1_counts AS (
    SELECT
        "name",
        "version",
        "L1_model",
        COUNT(*) AS cnt
    FROM STACKING.STACKING.MODEL
    GROUP BY "name", "version", "L1_model"
),

model_primary_l1 AS (
    SELECT
        "name",
        "version",
        "L1_model"
    FROM (
        SELECT
            mlc.*,
            ROW_NUMBER() OVER (PARTITION BY "name", "version"
                               ORDER BY cnt DESC, "L1_model") AS rn
        FROM model_l1_counts mlc
    )
    WHERE rn = 1
),

/*--------------------------------------------------------------------
   4.  Attach status to the primary L1_model of every (name , version)
--------------------------------------------------------------------*/
model_status_l1 AS (
    SELECT
        ms.status,
        mpl."L1_model"
    FROM model_status  ms
    JOIN model_primary_l1 mpl
          ON  ms."name"    = mpl."name"
          AND ms."version" = mpl."version"
    WHERE ms.status IS NOT NULL              -- keep only strong / soft
),

/*--------------------------------------------------------------------
   5.  Count how many models of each status share the same L1_model
--------------------------------------------------------------------*/
status_l1_counts AS (
    SELECT
        status,
        "L1_model",
        COUNT(*) AS occurrences
    FROM model_status_l1
    GROUP BY status, "L1_model"
),

/*--------------------------------------------------------------------
   6.  For each status keep the L1_model with the highest occurrence
--------------------------------------------------------------------*/
ranked AS (
    SELECT
        status,
        "L1_model",
        occurrences,
        ROW_NUMBER() OVER (PARTITION BY status
                           ORDER BY occurrences DESC, "L1_model") AS rn
    FROM status_l1_counts
)

SELECT
    status,
    "L1_model",
    occurrences
FROM ranked
WHERE rn = 1
ORDER BY status;