SELECT
  "browser",
  ROUND(AVG("session_duration") / 1e6, 4) AS "Average_Session_Duration"
FROM (
  SELECT
    "session_id",
    "browser",
    MAX("created_at") - MIN("created_at") AS "session_duration"
  FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.EVENTS
  GROUP BY "session_id", "browser"
)
GROUP BY "browser"
HAVING COUNT(DISTINCT "session_id") > 10
ORDER BY "Average_Session_Duration" ASC NULLS LAST
LIMIT 3;