-- Task: Using the `distract_2015` and `distract_2016` tables from the `nhtsa_traffic_fatalities` dataset, calculate the number of traffic accidents per 100,000 people caused by driver distraction in each U.S. state for the years 2015 and 2016. Exclude records where the `driver_distracted_by_name` field is 'Not Distracted', 'Unknown if Distracted', or 'Not Reported' (case-insensitive and trimmed). Join with the `us_states_area` table to obtain state names using `state_number` and `state_fips_code`. Use 2010 census population data from the `population_by_zip_2010` table in the `census_bureau_usa` dataset, joined with `zipcode_area` to aggregate populations by state. Calculate accident rates per 100,000 people and identify the top five states each year with the highest rates.

WITH accidents AS (
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
),

state_population AS (
  SELECT
    z.state_name,
    SUM(p.population) AS total_population
  FROM
    `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN
    `bigquery-public-data.utility_us.zipcode_area` AS z
      ON p.zipcode = z.zipcode
  WHERE
    p.population IS NOT NULL
  GROUP BY
    z.state_name
),

accident_rates AS (
  SELECT
    a.year,
    a.state_name,
    a.accident_count,
    s.total_population,
    ROUND((a.accident_count / s.total_population) * 100000, 4) AS accidents_per_100000_people,
    ROW_NUMBER() OVER(PARTITION BY a.year ORDER BY (a.accident_count / s.total_population) * 100000 DESC) AS rank
  FROM
    accidents AS a
  JOIN
    state_population AS s
      ON a.state_name = s.state_name
)

SELECT
  year,
  state_name,
  accidents_per_100000_people
FROM
  accident_rates
WHERE
  rank <= 5
ORDER BY
  year, rank;