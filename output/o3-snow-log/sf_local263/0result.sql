/* -----------------------------------------------------------
   1. For every (name,version,step) keep the best test score of
      the “Stack” model and the best score of all other models.
----------------------------------------------------------------*/
WITH stack_vs AS (   
    SELECT  "name",
            "version",
            "step",
            MAX(CASE WHEN UPPER("model") = 'STACK' THEN "test_score" END)    AS stack_score,
            MAX(CASE WHEN UPPER("model") <> 'STACK' THEN "test_score" END)  AS non_stack_max
    FROM    STACKING.STACKING.MODEL_SCORE
    GROUP BY "name", "version", "step"
    HAVING  MAX(CASE WHEN UPPER("model") = 'STACK' THEN 1 ELSE 0 END) = 1          -- keep steps that really contain a Stack model
),

/* -----------------------------------------------------------
   2. Decide, for each (name,version), whether it is “strong” or
      “soft”.
----------------------------------------------------------------*/
status_per_model AS (
    SELECT  "name",
            "version",
            CASE
                WHEN MAX(CASE WHEN stack_score > non_stack_max THEN 1 ELSE 0 END) = 1
                     THEN 'strong'
                WHEN MAX(CASE WHEN stack_score = non_stack_max THEN 1 ELSE 0 END) = 1
                     THEN 'soft'
            END                                                         AS status
    FROM    stack_vs
    GROUP BY "name", "version"
    HAVING  status IS NOT NULL                                          -- drop models that are neither strong nor soft
),

/* -----------------------------------------------------------
   3. List the L1_model(s) attached to every (name,version).
----------------------------------------------------------------*/
model_l1 AS (
    SELECT DISTINCT "name", "version", "L1_model"
    FROM   STACKING.STACKING.MODEL
),

/* -----------------------------------------------------------
   4. Count, for every status, how many times each L1_model
      appears.
----------------------------------------------------------------*/
status_l1 AS (
    SELECT  spm.status,
            ml."L1_model",
            COUNT( DISTINCT spm."name" || ':' || spm."version")  AS occurences
    FROM    status_per_model spm
    JOIN    model_l1         ml
           ON  spm."name"    = ml."name"
           AND spm."version" = ml."version"
    GROUP BY spm.status, ml."L1_model"
),

/* -----------------------------------------------------------
   5. Keep, per status, the L1_model with the highest occurrence.
----------------------------------------------------------------*/
ranked AS (
    SELECT  status,
            "L1_model",
            occurences,
            ROW_NUMBER() OVER (PARTITION BY status
                               ORDER BY occurences DESC NULLS LAST,
                                        "L1_model" ASC) AS rn
    FROM    status_l1
)

SELECT  status,
        "L1_model",
        occurences
FROM    ranked
WHERE   rn = 1
ORDER BY status;