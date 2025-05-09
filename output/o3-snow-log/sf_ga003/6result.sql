WITH completed_events AS (   -- one row per quick-play completion on 15-Sep-2018
    SELECT
        t."event_timestamp",

        /* board type */
        MAX(
            CASE
                WHEN f.value:"key"::STRING = 'board'
                THEN f.value:"value":"string_value"::STRING
            END
        ) AS "board",

        /* numeric score, if present, held in the “value” parameter */
        MAX(
            CASE
                WHEN f.value:"key"::STRING = 'value' THEN
                     COALESCE(
                         f.value:"value":"int_value"::FLOAT,
                         f.value:"value":"double_value"::FLOAT,
                         TRY_TO_NUMBER(f.value:"value":"string_value"::STRING)
                     )
            END
        ) AS "score"
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915" t,
         LATERAL FLATTEN(input => t."event_params") f
    WHERE t."event_name" = 'level_end_quickplay'
    GROUP BY t."event_timestamp"
)

SELECT
       "board",
       AVG("score") AS avg_score          -- AVG ignores NULL scores automatically
FROM completed_events
WHERE "board" IS NOT NULL
GROUP BY "board"
ORDER BY avg_score DESC NULLS LAST;