/* Three browsers with the shortest average session duration (seconds)
   – only browsers that appear in >10 distinct sessions                */
WITH session_durations AS (               -- per-session duration in seconds
    SELECT
        "session_id",
        ( MAX("created_at") - MIN("created_at") ) / 1000000.0  AS "session_duration_sec"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "session_id"
    HAVING COUNT(*) > 1                         -- keep sessions that have >1 event
),
session_browser AS (                -- browser associated with each session
    SELECT
        "session_id",
        MIN("browser") AS "browser"             -- browser is constant per session
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "session_id"
)
SELECT
    sb."browser",
    COUNT(*)                                                    AS "num_sessions",
    CAST(AVG(sd."session_duration_sec") AS NUMBER(38,4))        AS "avg_session_duration_sec"
FROM session_durations sd
JOIN session_browser sb
  ON sb."session_id" = sd."session_id"
GROUP BY sb."browser"
HAVING COUNT(*) > 10                         -- only browsers with >10 sessions
ORDER BY "avg_session_duration_sec" ASC
LIMIT 3;