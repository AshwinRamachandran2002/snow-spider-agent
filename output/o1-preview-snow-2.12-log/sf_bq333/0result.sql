SELECT
  "browser",
  AVG(("session_duration") / 1000000.0) AS "average_session_duration"
FROM
  (
    SELECT
      "browser",
      "session_id",
      MAX("created_at") - MIN("created_at") AS "session_duration"
    FROM
      "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS"
    WHERE
      "browser" IS NOT NULL
      AND "session_id" IS NOT NULL
      AND "created_at" IS NOT NULL
    GROUP BY
      "browser",
      "session_id"
  ) AS session_durations
GROUP BY
  "browser"
HAVING
  COUNT("session_id") > 10
ORDER BY
  "average_session_duration" ASC
LIMIT 3;