/*  Driver-distraction traffic-accident rates (per 100,000 people)
    for every U.S. state in 2015 and 2016, plus each year’s ranking
    (1 = highest rate).  Population denominator = 2010 national total. */

WITH
-- National population (2010 ZIP-level census, summed)
pop AS (
  SELECT SUM(population) AS us_pop_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
),

-- 2015 crashes where driver distraction is explicitly recorded
distracted_2015 AS (
  SELECT
    state_number,
    COUNT(DISTINCT consecutive_number) AS crashes_2015
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
  WHERE LOWER(driver_distracted_by_name) NOT IN ('not distracted',
                                                 'unknown if distracted',
                                                 'not reported')
  GROUP BY state_number
),

-- 2016 crashes (same exclusions)
distracted_2016 AS (
  SELECT
    state_number,
    COUNT(DISTINCT consecutive_number) AS crashes_2016
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
  WHERE LOWER(driver_distracted_by_name) NOT IN ('not distracted',
                                                 'unknown if distracted',
                                                 'not reported')
  GROUP BY state_number
),

-- Compute 2015 rates
rates_2015 AS (
  SELECT
    d.state_number,
    '2015' AS year,
    d.crashes_2015 AS crashes,
    ROUND(d.crashes_2015 * 100000.0 / p.us_pop_2010, 6) AS crashes_per_100k
  FROM distracted_2015 d
  CROSS JOIN pop p
),

-- Compute 2016 rates
rates_2016 AS (
  SELECT
    d.state_number,
    '2016' AS year,
    d.crashes_2016 AS crashes,
    ROUND(d.crashes_2016 * 100000.0 / p.us_pop_2010, 6) AS crashes_per_100k
  FROM distracted_2016 d
  CROSS JOIN pop p
),

-- Combine both years
all_rates AS (
  SELECT * FROM rates_2015
  UNION ALL
  SELECT * FROM rates_2016
),

-- Rank states within each year by highest rate
ranked AS (
  SELECT
    ar.*,
    DENSE_RANK() OVER (PARTITION BY year ORDER BY crashes_per_100k DESC) AS rate_rank
  FROM all_rates ar
)

-- Final result
SELECT
  year,
  state_number,
  crashes,
  crashes_per_100k,
  rate_rank
FROM ranked
ORDER BY
  year,
  rate_rank,
  state_number;