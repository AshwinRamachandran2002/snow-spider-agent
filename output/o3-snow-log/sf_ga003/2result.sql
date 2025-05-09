/*  Average quick-play score for every board size on 15-Sep-2018  */
WITH quickplay_completions AS (
    SELECT
        t."event_timestamp",
        t."user_pseudo_id",

        /* extract board type */
        MAX(
            IFF(
                f.value:"key"::STRING = 'board',
                f.value:"value":"string_value"::STRING,
                NULL
            )
        )                                                AS board,

        /* extract score, no matter which numeric field is populated */
        MAX(
            IFF(
                f.value:"key"::STRING = 'score',
                COALESCE(
                    f.value:"value":"int_value"::NUMBER,
                    f.value:"value":"double_value"::NUMBER,
                    f.value:"value":"float_value"::NUMBER,
                    TRY_TO_NUMBER(f.value:"value":"string_value"::STRING)
                ),
                NULL
            )
        )                                                AS score
    FROM "FIREBASE"."ANALYTICS_153293282"."EVENTS_20180915"  t,
         LATERAL FLATTEN(input => t."event_params")          f
    WHERE t."event_name" = 'level_end_quickplay'
    GROUP BY t."event_timestamp", t."user_pseudo_id"
)

SELECT
    board,
    AVG(score) AS avg_score
FROM quickplay_completions
WHERE board IS NOT NULL
GROUP BY board
ORDER BY avg_score DESC NULLS LAST;