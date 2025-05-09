/* ---------------------------------------------------------------
   Average score for every quick-play board size (S, M, L)
   on 15-Sep-2018.

   Step-1 :  Pull board size from the “level_end_quickplay” events.
   Step-2 :  Pull numeric score from the “post_score” events.
   Step-3 :  Join the two by user AND near-identical timestamps
             (≤ 1,000,000 µs  = 1 second) to pair each completion
             with the score it immediately generated.
   Step-4 :  Average the score per board size.
-----------------------------------------------------------------*/
WITH quickplay AS (      -- board size for each quick-play completion
    SELECT
           t."user_pseudo_id",
           t."event_timestamp"                       AS qp_ts,
           MAX(CASE WHEN f.value:"key" = 'board'
                    THEN f.value:"value":"string_value"::STRING END) AS board_type
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" t
         , LATERAL FLATTEN(INPUT => t."event_params") f
    WHERE t."event_name" = 'level_end_quickplay'
    GROUP BY t."user_pseudo_id", t."event_timestamp"
),
scores AS (            -- numeric score emitted right after completion
    SELECT
           t."user_pseudo_id",
           t."event_timestamp"                       AS score_ts,
           MAX(CASE WHEN f.value:"key" = 'score'
                    THEN COALESCE(f.value:"value":"int_value",
                                   f.value:"value":"double_value",
                                   f.value:"value":"float_value")::NUMBER END)
                                                         AS score
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" t
         , LATERAL FLATTEN(INPUT => t."event_params") f
    WHERE t."event_name" = 'post_score'
    GROUP BY t."user_pseudo_id", t."event_timestamp"
)
SELECT
       q.board_type,
       ROUND(AVG(s.score), 2) AS avg_score
FROM quickplay q
JOIN scores   s
  ON q."user_pseudo_id" = s."user_pseudo_id"
 AND ABS(q.qp_ts - s.score_ts) <= 1000000      -- within 1 second
WHERE q.board_type IN ('S','M','L')            -- quick-play board sizes
  AND s.score IS NOT NULL
GROUP BY q.board_type
ORDER BY avg_score DESC NULLS LAST;