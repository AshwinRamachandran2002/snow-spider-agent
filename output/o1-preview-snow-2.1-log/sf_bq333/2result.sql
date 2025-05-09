SELECT "browser", ROUND(AVG("session_duration"), 4) AS "Average_Session_Duration"
FROM (
    SELECT "session_id", "browser", (MAX("created_at") - MIN("created_at")) / 1000000 AS "session_duration"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
    GROUP BY "session_id", "browser"
) AS session_durations
GROUP BY "browser"
HAVING COUNT(DISTINCT "session_id") > 10
ORDER BY "Average_Session_Duration" ASC
LIMIT 3;