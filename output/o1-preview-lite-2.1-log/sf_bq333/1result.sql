SELECT
    "browser",
    AVG("session_duration") AS "average_session_duration"
FROM (
    SELECT
        "session_id",
        "browser",
        MAX("created_at") - MIN("created_at") AS "session_duration"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS"
    GROUP BY "session_id", "browser"
) AS session_durations
GROUP BY "browser"
HAVING COUNT(DISTINCT "session_id") > 10
ORDER BY "average_session_duration" ASC NULLS LAST
LIMIT 3;