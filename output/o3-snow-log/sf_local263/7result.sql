/*---------------------------------------------------------------
   1. For every dataset (name + version + step) compare the test
      score of the “Stack” model with the best score obtained by
      any non-Stack model.
----------------------------------------------------------------*/
WITH stack_vs_others AS (
    SELECT
        ms."name",
        ms."version",
        ms."step",
        MAX(CASE WHEN ms."model" = 'Stack' THEN ms."test_score" END)  AS "stack_test",
        MAX(CASE WHEN ms."model" <> 'Stack' THEN ms."test_score" END) AS "other_test"
    FROM STACKING.STACKING."MODEL_SCORE" ms
    GROUP BY ms."name", ms."version", ms."step"
    HAVING MAX(CASE WHEN ms."model" = 'Stack' THEN 1 ELSE 0 END) = 1   -- keep steps that contain a Stack entry
),

/*----------------------------------------------------------------
   2. Decide, for every dataset (name + version), whether the whole
      solution is “strong” or “soft”.
----------------------------------------------------------------*/
status_per_solution AS (
    SELECT
        "name",
        "version",
        CASE
            WHEN MAX(CASE WHEN "stack_test" > NVL("other_test", -1e100) THEN 1 ELSE 0 END) = 1
                 THEN 'strong'                              -- Stack strictly better in at least one step
            WHEN MAX(CASE WHEN "stack_test" = "other_test" THEN 1 ELSE 0 END) = 1
                 THEN 'soft'                                -- Stack equals best non-Stack (and never better)
        END AS "status"
    FROM stack_vs_others
    GROUP BY "name", "version"
),

/*----------------------------------------------------------------
   3. Retrieve the L1_model used for every dataset (name + version).
      (If several rows exist, they normally contain the same value;
       DISTINCT keeps one.)
----------------------------------------------------------------*/
l1_per_solution AS (
    SELECT DISTINCT
        m."name",
        m."version",
        m."L1_model"
    FROM STACKING.STACKING."MODEL" m
),

/*----------------------------------------------------------------
   4. Attach status to each L1_model, then count occurrences.
----------------------------------------------------------------*/
solution_with_status AS (
    SELECT
        s."status",
        l."L1_model",
        s."name",
        s."version"
    FROM status_per_solution   s
    JOIN l1_per_solution       l
      ON s."name"    = l."name"
     AND s."version" = l."version"
),

occurrences AS (
    SELECT
        "status",
        "L1_model",
        COUNT(DISTINCT "name" || ':' || "version") AS cnt
    FROM solution_with_status
    GROUP BY "status", "L1_model"
),

/*----------------------------------------------------------------
   5. Rank L1_models by frequency within each status and keep the top
      one for “strong” and for “soft”.
----------------------------------------------------------------*/
ranked AS (
    SELECT
        "status",
        "L1_model",
        cnt,
        ROW_NUMBER() OVER (PARTITION BY "status"
                           ORDER BY cnt DESC NULLS LAST) AS rn
    FROM occurrences
)

SELECT
    "status",
    "L1_model",
    cnt
FROM ranked
WHERE rn = 1
ORDER BY "status";