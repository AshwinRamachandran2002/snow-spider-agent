SELECT
  ROUND((COUNTIF(severe_injuries > 1) / COUNT(*)) * 100, 4) AS Percentage
FROM (
  SELECT
    a.state_number,
    a.consecutive_number,
    COUNT(DISTINCT p.person_number) AS person_count,
    SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END) AS severe_injuries
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` AS p
    ON a.state_number = p.state_number AND a.consecutive_number = p.consecutive_number
  WHERE a.month_of_crash BETWEEN 1 AND 8
    AND a.year_of_crash = 2015
  GROUP BY a.state_number, a.consecutive_number
  HAVING COUNT(DISTINCT p.person_number) > 1
)