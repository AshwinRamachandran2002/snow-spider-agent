WITH state_populations AS (
  SELECT z.state_code, SUM(p.population) AS state_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area` AS z
    ON p.zipcode = z.zipcode
  GROUP BY z.state_code
),
accidents_2015 AS (
  SELECT a.state_number, s.state_name, s.state_abbreviation, COUNT(DISTINCT a.consecutive_number) AS accident_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015` AS d
    ON a.state_number = d.state_number AND a.consecutive_number = d.consecutive_number
  JOIN `bigquery-public-data.utility_us.us_states_area` AS s
    ON CAST(a.state_number AS STRING) = s.state_fips_code
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a.state_number, s.state_name, s.state_abbreviation
),
accidents_2016 AS (
  SELECT a.state_number, s.state_name, s.state_abbreviation, COUNT(DISTINCT a.consecutive_number) AS accident_count
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016` AS d
    ON a.state_number = d.state_number AND a.consecutive_number = d.consecutive_number
  JOIN `bigquery-public-data.utility_us.us_states_area` AS s
    ON CAST(a.state_number AS STRING) = s.state_fips_code
  WHERE d.driver_distracted_by_name NOT IN ('Not Distracted', 'Unknown if Distracted', 'Not Reported')
  GROUP BY a.state_number, s.state_name, s.state_abbreviation
),
accidents AS (
  SELECT '2015' AS year, state_abbreviation, state_name, accident_count FROM accidents_2015
  UNION ALL
  SELECT '2016' AS year, state_abbreviation, state_name, accident_count FROM accidents_2016
),
accidents_with_population AS (
  SELECT
    a.year,
    a.state_name AS State,
    a.accident_count,
    p.state_population,
    ROUND(a.accident_count / (p.state_population / 100000), 4) AS Accidents_per_100k
  FROM accidents AS a
  JOIN state_populations AS p
    ON a.state_abbreviation = p.state_code
)
SELECT year, State, Accidents_per_100k
FROM (
  SELECT *,
    ROW_NUMBER() OVER(PARTITION BY year ORDER BY Accidents_per_100k DESC) AS rn
  FROM accidents_with_population
)
WHERE rn <= 5
ORDER BY year, Accidents_per_100k DESC;