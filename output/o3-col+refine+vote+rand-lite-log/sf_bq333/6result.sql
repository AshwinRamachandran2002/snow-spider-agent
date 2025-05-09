WITH sessions AS (
    SELECT  "browser",
            (MAX("created_at") - MIN("created_at")) / 1000000 AS "session_seconds"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP   BY "browser", "session_id"
)
SELECT  "browser",
        AVG("session_seconds") AS "avg_session_seconds"
FROM    sessions
GROUP   BY "browser"
HAVING  COUNT(*) > 10
ORDER   BY "avg_session_seconds" ASC
LIMIT 3;