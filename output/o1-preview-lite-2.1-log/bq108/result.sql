WITH total_accidents AS (
  SELECT COUNT(DISTINCT CONCAT(state_number, '-', consecutive_number)) AS total_accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
),
accidents_with_multiple_people_and_severe_injuries AS (
  SELECT COUNT(DISTINCT CONCAT(state_number, '-', consecutive_number)) AS accidents_count
  FROM (
    SELECT state_number, consecutive_number
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
    WHERE month_of_crash BETWEEN 1 AND 8
    GROUP BY state_number, consecutive_number
    HAVING COUNT(person_number) > 1 AND SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END) > 1
  ) AS subquery
)
SELECT
  ROUND((accidents_with_multiple_people_and_severe_injuries.accidents_count * 100.0) / total_accidents.total_accidents, 4) AS Percentage
FROM total_accidents, accidents_with_multiple_people_and_severe_injuries;