WITH accidents AS (
  SELECT "consecutive_number",
         COUNT(DISTINCT "person_number") AS total_persons,
         SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END) AS severe_injuries
  FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."PERSON_2015"
  WHERE "month_of_crash" BETWEEN 1 AND 8
  GROUP BY "consecutive_number"
  HAVING COUNT(DISTINCT "person_number") > 1
)
SELECT
  ROUND((COUNT(CASE WHEN severe_injuries > 1 THEN 1 END) * 100.0) / COUNT(*), 4) AS "percentage"
FROM accidents;