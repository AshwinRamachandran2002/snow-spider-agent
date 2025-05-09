SELECT 'Intimates' AS "Category",
       ROUND(AVG("session_duration_microseconds") / 60000000.0, 4) AS "Average_Time_Minutes"
FROM (
  SELECT e."session_id", MAX(e."created_at") - MIN(e."created_at") AS "session_duration_microseconds"
  FROM "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."EVENTS" e
  WHERE e."uri" ILIKE '%Intimates%'
  GROUP BY e."session_id"
) AS session_durations;