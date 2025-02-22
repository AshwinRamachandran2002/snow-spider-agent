-- Task: Retrieve the number of traffic accidents caused by driver distraction in each U.S. state for the years 2015 and 2016, excluding cases where the driver's distraction status is 'Not Distracted', 'Unknown if Distracted', or 'Not Reported'. Limit the results to 100 rows.

SELECT
  '2015' AS year,
  s.state_name,
  COUNT(DISTINCT d.consecutive_number) AS accident_count
FROM
  `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015` AS d
JOIN
  `bigquery-public-data.utility_us.us_states_area` AS s
  ON d.state_number = CAST(s.state_fips_code AS INT64)
WHERE
  LOWER(TRIM(d.driver_distracted_by_name)) NOT IN ('not distracted', 'unknown if distracted', 'not reported')
GROUP BY
  s.state_name

UNION ALL

SELECT
  '2016' AS year,
  s.state_name,
  COUNT(DISTINCT d.consecutive_number) AS accident_count
FROM
  `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016` AS d
JOIN
  `bigquery-public-data.utility_us.us_states_area` AS s
  ON d.state_number = CAST(s.state_fips_code AS INT64)
WHERE
  LOWER(TRIM(d.driver_distracted_by_name)) NOT IN ('not distracted', 'unknown if distracted', 'not reported')
GROUP BY
  s.state_name
ORDER BY
  year, accident_count DESC
LIMIT 100;