WITH stack_scores AS (
    SELECT
        m."name",
        m."version",
        m."step",
        m."L1_model",
        s."test_score" AS "stack_score",
        (SELECT MAX(ns."test_score")
         FROM "STACKING"."STACKING"."MODEL_SCORE" ns
         WHERE ns."model" <> 'Stack' AND ns."name" = m."name" AND ns."version" = m."version" AND ns."step" = m."step"
        ) AS "max_non_stack_score"
    FROM
        "STACKING"."STACKING"."MODEL" m
    JOIN
        "STACKING"."STACKING"."MODEL_SCORE" s
    ON
        m."name" = s."name" AND m."version" = s."version" AND m."step" = s."step"
    WHERE
        s."model" = 'Stack'
),
status_data AS (
    SELECT
        "L1_model",
        CASE
            WHEN "stack_score" > "max_non_stack_score" THEN 'strong'
            WHEN "stack_score" = "max_non_stack_score" THEN 'soft'
        END AS "Status"
    FROM
        stack_scores
    WHERE
        "stack_score" >= "max_non_stack_score"
),
occurrences AS (
    SELECT
        "Status",
        "L1_model",
        COUNT(*) AS "Occurrences",
        ROW_NUMBER() OVER (PARTITION BY "Status" ORDER BY COUNT(*) DESC) AS rn
    FROM
        status_data
    WHERE
        "Status" IS NOT NULL
    GROUP BY
        "Status",
        "L1_model"
)
SELECT
    "Status",
    "L1_model",
    "Occurrences"
FROM
    occurrences
WHERE
    rn = 1
ORDER BY
    CASE WHEN "Status" = 'strong' THEN 0 WHEN "Status" = 'soft' THEN 1 END
;