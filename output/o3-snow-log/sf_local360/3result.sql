/* ---------------------------------------------------------------
   1.  For every session, locate the first moment a “/detail” view
       or “/complete” conversion happened.
   2.  Count, per session, how many events with a non-empty
       search_type occurred BEFORE that first moment.
   3.  Find the minimum of those counts.
   4.  Pick the sessions whose count equals that minimum.
   5.  For the qualifying sessions, list every pre-event
       (session, path, search_type) that happened before the first
       “/detail”/“/complete”.
-----------------------------------------------------------------*/
WITH first_detail AS (          -- Step-1
    SELECT
        "session",
        MIN("stamp") AS "first_detail_time"
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE "path" ILIKE '%/detail%'
       OR "path" ILIKE '%/complete%'
    GROUP BY "session"
),
pre_counts AS (                 -- Step-2
    SELECT
        a."session",
        COUNT(*) AS "pre_events"
    FROM LOG.LOG.ACTIVITY_LOG  a
    JOIN first_detail          f
      ON a."session" = f."session"
    WHERE a."stamp" < f."first_detail_time"
      AND a."search_type" <> ''
    GROUP BY a."session"
),
min_pre AS (                    -- Step-3
    SELECT MIN("pre_events") AS "min_pre_events"
    FROM pre_counts
),
target_sessions AS (            -- Step-4
    SELECT p."session"
    FROM pre_counts p
    JOIN min_pre  m
      ON p."pre_events" = m."min_pre_events"
),
final_pre_events AS (           -- Step-5
    SELECT
        a."session",
        a."path",
        a."search_type"
    FROM LOG.LOG.ACTIVITY_LOG  a
    JOIN first_detail          f
      ON a."session" = f."session"
    JOIN target_sessions       t
      ON a."session" = t."session"
    WHERE a."stamp" < f."first_detail_time"
      AND a."search_type" <> ''
)
SELECT
    "session",
    "path",
    "search_type"
FROM final_pre_events
ORDER BY "session", "path";