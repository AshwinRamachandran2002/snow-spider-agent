WITH total_accidents AS (
  SELECT COUNT(DISTINCT consecutive_number) AS total
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE month_of_crash BETWEEN 1 AND 8
),
accidents_with_multiple_people_and_severe_injuries AS (
  SELECT COUNT(*) AS count
  FROM (
    SELECT consecutive_number
    FROM (
      SELECT consecutive_number,
             COUNT(*) AS person_count,
             SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END) AS severe_injuries_count
      FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
      WHERE month_of_crash BETWEEN 1 AND 8
      GROUP BY consecutive_number
    )
    WHERE person_count >= 2 AND severe_injuries_count >= 2
  )
)
SELECT ROUND((accidents_with_multiple_people_and_severe_injuries.count * 100.0) / total_accidents.total, 4) AS Percentage
FROM accidents_with_multiple_people_and_severe_injuries, total_accidents;