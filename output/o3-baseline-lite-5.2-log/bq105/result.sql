--  Traffic accidents caused by driver distraction (excluding “Not Distracted”,
--  “Unknown if Distracted”, and “Not Reported”) per 100,000 residents,
--  by state for 2015‑2016, together with a flag for each year’s Top‑5 states
WITH pop_state AS (   -- 2010 Census population by state
  SELECT
    z.state_name,
    SUM(p.population) AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`   p
  JOIN `bigquery-public-data.utility_us.zipcode_area`                   z
    ON LPAD(CAST(p.zipcode AS STRING), 5, '0') = z.zipcode              -- keep leading 0’s
  GROUP BY z.state_name
),
/*  Accidents in which at least one driver was recorded as distracted
    (excluding the three non‑informative categories)                  */
acc_dis_2015 AS (
  SELECT DISTINCT
    a.state_name,
    a.consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`  a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`  d
    ON  a.state_number      = d.state_number
   AND a.consecutive_number = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN
        ('Not Distracted','Unknown if Distracted','Not Reported')
),
acc_dis_2016 AS (
  SELECT DISTINCT
    a.state_name,
    a.consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`  a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`  d
    ON  a.state_number      = d.state_number
   AND a.consecutive_number = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN
        ('Not Distracted','Unknown if Distracted','Not Reported')
),
state_counts AS (     -- number of distraction–related crashes per state & year
  SELECT 2015 AS year , state_name, COUNT(*) AS distracted_accidents
  FROM acc_dis_2015 GROUP BY state_name
  UNION ALL
  SELECT 2016       , state_name, COUNT(*) AS distracted_accidents
  FROM acc_dis_2016 GROUP BY state_name
),
rates AS (
  SELECT
    sc.year,
    sc.state_name,
    sc.distracted_accidents,
    ps.population_2010,
    100000 * sc.distracted_accidents / ps.population_2010 AS accidents_per_100k
  FROM state_counts sc
  JOIN pop_state   ps USING (state_name)
),
ranked AS (           -- rank states within each year by rate
  SELECT
    r.*,
    RANK() OVER (PARTITION BY year ORDER BY accidents_per_100k DESC) AS state_rank
  FROM rates r
)
SELECT
  year,
  state_name,
  distracted_accidents,
  population_2010,
  ROUND(accidents_per_100k, 4) AS accidents_per_100k,
  state_rank,
  CASE WHEN state_rank <= 5 THEN TRUE ELSE FALSE END AS top5_each_year
FROM ranked
ORDER BY year, accidents_per_100k DESC;