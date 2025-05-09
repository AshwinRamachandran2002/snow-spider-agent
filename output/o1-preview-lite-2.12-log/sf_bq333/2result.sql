SELECT 
  "browser", 
  ROUND(AVG("session_duration_seconds"), 4) AS "average_session_duration"
FROM (
  SELECT 
    "session_id", 
    "browser", 
    (MAX("created_at") - MIN("created_at")) / 1000000 AS "session_duration_seconds"
  FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS"
  WHERE "browser" IS NOT NULL 
    AND "session_id" IS NOT NULL 
    AND "created_at" IS NOT NULL
  GROUP BY "session_id", "browser"
) AS session_durations
GROUP BY "browser"
HAVING COUNT(*) > 10
ORDER BY "average_session_duration" ASC
LIMIT 3;