SELECT "browser",
       AVG("session_duration_in_seconds") AS "average_session_duration"
FROM (
    SELECT "browser",
           "session_id",
           (MAX("created_at") - MIN("created_at")) / 1000000 AS "session_duration_in_seconds"
    FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS"
    WHERE "created_at" IS NOT NULL
      AND "session_id" IS NOT NULL
    GROUP BY "browser", "session_id"
    HAVING (MAX("created_at") - MIN("created_at")) > 0
) AS "session_durations"
GROUP BY "browser"
HAVING COUNT(DISTINCT "session_id") > 10
ORDER BY "average_session_duration" ASC
LIMIT 3;