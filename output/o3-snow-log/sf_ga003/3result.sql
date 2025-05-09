/* Avg numeric performance metric (“score / moves / steps / points”)
   by board type for Quick-Play completions on 15-Sep-2018          */

WITH quickplay_completions AS (
    SELECT
        /* board label (S, M, …) */
        MAX(
            CASE
                WHEN f.value:"key"::STRING = 'board'
                THEN f.value:"value":"string_value"::STRING
            END
        )                                                        AS board ,

        /* any numeric metric that looks like a score */
        MAX(
            CASE
                WHEN f.value:"key"::STRING IN ('score','points','moves','steps')
                THEN COALESCE(
                        f.value:"value":"int_value",
                        f.value:"value":"double_value"
                     )::NUMBER
            END
        )                                                        AS score
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" e
         ,LATERAL FLATTEN (INPUT => e."event_params") f
    WHERE e."event_name" = 'level_end_quickplay'
    GROUP BY e."event_timestamp"         -- one row per completion event
)

SELECT
    board,
    AVG(score)   AS avg_score
FROM quickplay_completions
WHERE board IS NOT NULL
GROUP BY board
ORDER BY avg_score DESC NULLS LAST;