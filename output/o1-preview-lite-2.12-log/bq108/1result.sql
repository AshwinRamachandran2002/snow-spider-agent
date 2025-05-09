SELECT ((COUNTIF(severe_injury_count > 1) / COUNT(*)) * 100) AS Percentage
FROM
(
  SELECT p.consecutive_number,
         COUNT(DISTINCT p.person_number) AS person_count,
         SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END) AS severe_injury_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015` AS p
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
    ON p.consecutive_number = a.consecutive_number
  WHERE a.month_of_crash BETWEEN 1 AND 8
  GROUP BY p.consecutive_number
  HAVING person_count > 1
);