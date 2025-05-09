/*  Traffic accidents caused by driver distraction per 100,000 residents
    (population from 2010 census ZIP data) and the five states with the
    highest rates in 2015 and 2016                                          */

WITH pop AS (   -- 2010 population by state
  SELECT
    z.state_name,
    SUM(p.population) AS population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area`                 AS z
       ON CAST(p.zipcode AS INT64)=CAST(z.zipcode AS INT64)           -- handles leading‑zero ZIP codes
  GROUP BY z.state_name
),
distraction_accidents AS (          -- accidents with at least one distracted driver
  SELECT
    2015 AS year,
    a.state_name,
    a.consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`  AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`  AS d
    ON a.state_number = d.state_number
   AND a.consecutive_number = d.consecutive_number
  WHERE LOWER(d.driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')

  UNION DISTINCT

  SELECT
    2016,
    a.state_name,
    a.consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`  AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`  AS d
    ON a.state_number = d.state_number
   AND a.consecutive_number = d.consecutive_number
  WHERE LOWER(d.driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
),
accident_counts AS (                -- count of such accidents by state & year
  SELECT
    year,
    state_name,
    COUNT(DISTINCT consecutive_number) AS accidents
  FROM distraction_accidents
  GROUP BY year, state_name
),
rates AS (                          -- accidents per 100,000 residents
  SELECT
    ac.year,
    ac.state_name,
    ac.accidents,
    p.population,
    ac.accidents * 100000.0 / p.population AS accidents_per_100k
  FROM accident_counts ac
  JOIN pop            p
    ON ac.state_name = p.state_name
),
ranked AS (                         -- rank states within each year
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY year ORDER BY accidents_per_100k DESC) AS rnk
  FROM rates
)
SELECT
  year,
  state_name,
  ROUND(accidents_per_100k, 4) AS accidents_per_100k,
  rnk                          AS rank_within_year
FROM ranked
WHERE rnk <= 5                 -- top 5 states each year
ORDER BY year, rnk, state_name;