/*  Average “score” (first numeric param ≠ firebase_screen_id) by board type
    for quick-play completions on 15-Sep-2018.                         */
SELECT
       agg."board_type",
       AVG(agg."score") AS "avg_score"
FROM (
        SELECT
               MAX( CASE WHEN f.value:"key"::STRING = 'board'
                         THEN f.value:"value":"string_value"::STRING END )      AS "board_type",
               MAX( CASE
                         WHEN f.value:"key"::STRING <> 'firebase_screen_id'
                          AND ( f.value:"value":"int_value"  IS NOT NULL
                             OR f.value:"value":"double_value" IS NOT NULL )
                         THEN COALESCE( f.value:"value":"double_value",
                                        f.value:"value":"int_value")::FLOAT
                    END )                                                      AS "score"
        FROM   FIREBASE.ANALYTICS_153293282."EVENTS_20180915" t,
               LATERAL FLATTEN( INPUT => t."event_params") f
        WHERE  t."event_name" = 'level_end_quickplay'
        GROUP  BY t."event_timestamp"        -- one row per completion
     ) agg
GROUP  BY agg."board_type"
ORDER  BY "avg_score" DESC NULLS LAST;