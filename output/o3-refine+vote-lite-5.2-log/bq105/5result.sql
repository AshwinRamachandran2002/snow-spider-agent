-- Driver‑distraction accident rates (per 100 000 residents) and
-- the five states with the highest rates in 2015 and 2016
WITH population AS (   -- 2010 Census population by state
  SELECT
    z.state_name,
    SUM(p.population) AS pop_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area` AS z
    ON CAST(p.zipcode AS INT64) = CAST(z.zipcode AS INT64)
  GROUP BY z.state_name
),
-- 2015 – accidents in which ≥1 driver was recorded as distracted
distract_2015 AS (
  SELECT
    a.state_name,
    COUNT(DISTINCT CONCAT(a.state_number,'-',a.consecutive_number)) AS acc_2015
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`  AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`  AS d
    ON a.state_number = d.state_number
   AND a.consecutive_number = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN
        ('Not Distracted','Unknown if Distracted','Not Reported')
  GROUP BY a.state_name
),
-- 2016 – same logic
distract_2016 AS (
  SELECT
    a.state_name,
    COUNT(DISTINCT CONCAT(a.state_number,'-',a.consecutive_number)) AS acc_2016
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`  AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`  AS d
    ON a.state_number = d.state_number
   AND a.consecutive_number = d.consecutive_number
  WHERE d.driver_distracted_by_name NOT IN
        ('Not Distracted','Unknown if Distracted','Not Reported')
  GROUP BY a.state_name
),
-- accident rates per 100 000 population
rates AS (
  SELECT
    p.state_name,
    COALESCE(d15.acc_2015,0) AS acc_2015,
    COALESCE(d16.acc_2016,0) AS acc_2016,
    p.pop_2010,
    -- per‑capita rates
    ROUND(COALESCE(d15.acc_2015,0) * 100000.0 / p.pop_2010, 4) AS rate_2015,
    ROUND(COALESCE(d16.acc_2016,0) * 100000.0 / p.pop_2010, 4) AS rate_2016
  FROM population p
  LEFT JOIN distract_2015 d15 USING (state_name)
  LEFT JOIN distract_2016 d16 USING (state_name)
)
-- return the top‑5 states for each year
SELECT *
FROM (
  SELECT '2015' AS year,
         state_name,
         rate_2015 AS accidents_per_100k,
         ROW_NUMBER() OVER (ORDER BY rate_2015 DESC) AS rn
  FROM rates

  UNION ALL

  SELECT '2016' AS year,
         state_name,
         rate_2016 AS accidents_per_100k,
         ROW_NUMBER() OVER (ORDER BY rate_2016 DESC) AS rn
  FROM rates
)
WHERE rn <= 5
ORDER BY year, accidents_per_100k DESC;