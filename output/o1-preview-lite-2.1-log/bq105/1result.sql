WITH state_populations AS (
  SELECT 
    z.state_name, 
    SUM(p.population) AS state_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area` AS z
    ON p.zipcode = z.zipcode
  GROUP BY z.state_name
),
accidents AS (
  SELECT 
    a.state_name, 
    COUNT(DISTINCT d.consecutive_number) AS accident_count, 
    2015 AS year
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015` AS d
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
    ON d.state_number = a.state_number AND d.consecutive_number = a.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a.state_name

  UNION ALL

  SELECT 
    a.state_name, 
    COUNT(DISTINCT d.consecutive_number) AS accident_count, 
    2016 AS year
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016` AS d
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
    ON d.state_number = a.state_number AND d.consecutive_number = a.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a.state_name
)
SELECT 
  year AS Year, 
  state_name AS State, 
  ROUND(accidents_per_100k, 4) AS Accidents_per_100000_people
FROM (
  SELECT 
    a.year, 
    a.state_name, 
    (a.accident_count * 100000.0) / sp.state_population AS accidents_per_100k,
    ROW_NUMBER() OVER (PARTITION BY a.year ORDER BY (a.accident_count * 100000.0) / sp.state_population DESC) AS rn
  FROM accidents AS a
  JOIN state_populations AS sp
    ON a.state_name = sp.state_name
)
WHERE rn <= 5
ORDER BY Year, rn;