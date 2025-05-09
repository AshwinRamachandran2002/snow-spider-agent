WITH state_populations AS (
  SELECT 
    za.state_name, 
    SUM(p.population) AS state_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area` AS za
    ON p.zipcode = za.zipcode
  WHERE za.state_name IS NOT NULL
  GROUP BY za.state_name
),

distraction_accidents_2015 AS (
  SELECT 
    a.state_name,
    COUNT(DISTINCT a.consecutive_number) AS accident_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015` AS d
    ON a.state_number = d.state_number AND a.consecutive_number = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a.state_name
),

distraction_accidents_2016 AS (
  SELECT 
    a.state_name,
    COUNT(DISTINCT a.consecutive_number) AS accident_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016` AS d
    ON a.state_number = d.state_number AND a.consecutive_number = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a.state_name
),

accidents_rates_2015 AS (
  SELECT
    '2015' AS Year,
    da.state_name,
    (CAST(da.accident_count AS FLOAT64) / sp.state_population) * 100000.0 AS accidents_per_100k
  FROM distraction_accidents_2015 AS da
  JOIN state_populations AS sp
    ON da.state_name = sp.state_name
),

accidents_rates_2016 AS (
  SELECT
    '2016' AS Year,
    da.state_name,
    (CAST(da.accident_count AS FLOAT64) / sp.state_population) * 100000.0 AS accidents_per_100k
  FROM distraction_accidents_2016 AS da
  JOIN state_populations AS sp
    ON da.state_name = sp.state_name
),

accidents_rates AS (
  SELECT * FROM accidents_rates_2015
  UNION ALL
  SELECT * FROM accidents_rates_2016
)

SELECT Year, State, ROUND(accidents_per_100k, 4) AS Accidents_per_100k
FROM (
  SELECT
    Year,
    state_name AS State,
    accidents_per_100k,
    ROW_NUMBER() OVER (PARTITION BY Year ORDER BY accidents_per_100k DESC) AS rn
  FROM accidents_rates
)
WHERE rn <= 5
ORDER BY Year, Accidents_per_100k DESC;