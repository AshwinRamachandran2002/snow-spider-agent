WITH total_accidents AS (
  SELECT COUNT(DISTINCT a."consecutive_number") AS total_accidents
  FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015 a
  WHERE a."month_of_crash" BETWEEN 1 AND 8
),
accidents_with_multiple_severe_injuries AS (
  SELECT COUNT(*) AS severe_accidents
  FROM (
    SELECT p."consecutive_number"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015 p
    JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015 a
      ON p."consecutive_number" = a."consecutive_number"
    WHERE a."month_of_crash" BETWEEN 1 AND 8
    GROUP BY p."consecutive_number"
    HAVING COUNT(DISTINCT p."person_number") > 1
      AND SUM(CASE WHEN p."injury_severity" = 4 THEN 1 ELSE 0 END) > 1
  ) sub
)
SELECT
  ROUND((accidents_with_multiple_severe_injuries.severe_accidents * 100.0) / total_accidents.total_accidents, 4) AS "percentage_of_accidents"
FROM
  total_accidents, accidents_with_multiple_severe_injuries;