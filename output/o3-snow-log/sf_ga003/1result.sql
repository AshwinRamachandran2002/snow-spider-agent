-- Average score per board type for quick-play completions on 15-Sep-2018
WITH board_events AS (          -- each quick-play completion holding a “board” value
    SELECT
        t."user_pseudo_id",
        t."event_timestamp"                                     AS board_ts,
        f.value:"value":"string_value"::STRING                  AS board
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" t,
         LATERAL FLATTEN (INPUT => t."event_params") f
    WHERE t."event_name" ILIKE '%_end_quickplay%'               -- completion events
      AND f.value:"key"::STRING = 'board'
),
score_events AS (              -- every score that might pair to a board event
    SELECT
        t."user_pseudo_id",
        t."event_timestamp"                                     AS score_ts,
        COALESCE( f.value:"value":"int_value"::NUMBER,
                  TRY_TO_NUMBER(f.value:"value":"string_value"::STRING) ) AS score
    FROM FIREBASE.ANALYTICS_153293282."EVENTS_20180915" t,
         LATERAL FLATTEN (INPUT => t."event_params") f
    WHERE t."event_name" = 'post_score'
      AND f.value:"key"::STRING = 'score'
),
paired_scores AS (             -- first score within 60 s of each board event
    SELECT
        b.board,
        s.score,
        ROW_NUMBER() OVER (PARTITION BY b."user_pseudo_id", b.board_ts
                           ORDER BY s.score_ts) AS rn
    FROM board_events b
    JOIN score_events s
      ON  s."user_pseudo_id" = b."user_pseudo_id"
      AND s.score_ts BETWEEN b.board_ts AND b.board_ts + 60000000  -- 60 s window
)
SELECT
       board,
       AVG(score) AS avg_score
FROM   paired_scores
WHERE  rn = 1                                 -- keep the first qualifying score
GROUP  BY board
ORDER  BY avg_score DESC NULLS LAST;