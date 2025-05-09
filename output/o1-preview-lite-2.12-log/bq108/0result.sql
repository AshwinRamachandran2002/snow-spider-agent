SELECT 
  ROUND((COUNTIF(severe_injury_count > 1) / COUNT(*)) * 100, 4) AS Percentage
FROM (
  SELECT a.`consecutive_number`,
         SUM(CASE WHEN p.`injury_severity` = 4 THEN 1 ELSE 0 END) AS severe_injury_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` AS p
    ON a.`consecutive_number` = p.`consecutive_number`
  WHERE a.`month_of_crash` BETWEEN 1 AND 8
  GROUP BY a.`consecutive_number`
  HAVING COUNT(DISTINCT p.`person_number`) > 1
)