WITH pop AS (   -- 2010 Census population by state (sum of ZIP populations)
  SELECT 
    z.state_name,
    SUM(p.population) AS population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area`               AS z
    ON LPAD(p.zipcode,5,'0') = z.zipcode
  GROUP BY z.state_name
),
-------------------------------------------------------------------
distracted_2015 AS (   -- crashes in 2015 with ≥1 distracted driver
  SELECT DISTINCT state_number, consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
),
distracted_2016 AS (   -- crashes in 2016 with ≥1 distracted driver
  SELECT DISTINCT state_number, consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
),
-------------------------------------------------------------------
acc AS (          -- number of such crashes per state & year
  SELECT 2015 AS year, a.state_name, COUNT(DISTINCT a.consecutive_number) AS accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
  JOIN distracted_2015 d
    ON a.state_number      = d.state_number
   AND a.consecutive_number = d.consecutive_number
  GROUP BY a.state_name

  UNION ALL

  SELECT 2016, a.state_name, COUNT(DISTINCT a.consecutive_number)
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
  JOIN distracted_2016 d
    ON a.state_number      = d.state_number
   AND a.consecutive_number = d.consecutive_number
  GROUP BY a.state_name
),
-------------------------------------------------------------------
rates AS (        -- accidents per 100,000 residents
  SELECT 
    a.year,
    a.state_name,
    a.accidents,
    p.population,
    100000.0 * a.accidents / p.population AS accidents_per_100k
  FROM acc  AS a
  JOIN pop  AS p
    ON a.state_name = p.state_name
),
-------------------------------------------------------------------
ranked AS (       -- rank and flag top‑5 states each year
  SELECT 
    r.*,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY accidents_per_100k DESC) AS state_rank,
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY year ORDER BY accidents_per_100k DESC) <= 5 
         THEN TRUE ELSE FALSE END                                          AS is_top5
  FROM rates r
)
-------------------------------------------------------------------
SELECT *
FROM ranked
ORDER BY year, state_rank;