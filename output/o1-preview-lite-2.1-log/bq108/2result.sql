WITH total_accidents AS (
  SELECT COUNT(DISTINCT `consecutive_number`) AS total_accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
  WHERE `month_of_crash` BETWEEN 1 AND 8
),
accidents_meeting_criteria AS (
  SELECT COUNT(*) AS accidents_with_multiple_severe_injuries
  FROM (
    SELECT `consecutive_number`
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
    WHERE `month_of_crash` BETWEEN 1 AND 8
    GROUP BY `consecutive_number`
    HAVING COUNT(`person_number`) > 1
       AND SUM(CASE WHEN `injury_severity` = 4 THEN 1 ELSE 0 END) > 1
  )
)
SELECT 
  ROUND((accidents_meeting_criteria.accidents_with_multiple_severe_injuries / total_accidents.total_accidents) * 100, 4) AS Percentage
FROM accidents_meeting_criteria, total_accidents;