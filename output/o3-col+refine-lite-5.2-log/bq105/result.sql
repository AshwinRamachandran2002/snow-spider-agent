/*  Driver‑distraction crash rates (per 100 000 residents)  
    – top 5 states in 2015 and 2016                                    */

WITH pop AS (   -- 2010 Census population summed to state level
  SELECT
    z.state_name,
    SUM(p.population) AS pop_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area`                   AS z
    ON  p.zipcode = z.zipcode
  GROUP BY z.state_name
),

distracted AS (   -- crash counts that involved at least one distracted driver
  /* ----- 2015 ----- */
  SELECT
    a.state_name,
    2015 AS year,
    COUNT(DISTINCT a.consecutive_number) AS crashes
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`  AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`  AS d
    ON  a.state_number       = d.state_number
    AND a.consecutive_number = d.consecutive_number
  WHERE LOWER(d.driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
  GROUP BY a.state_name

  UNION ALL

  /* ----- 2016 ----- */
  SELECT
    a.state_name,
    2016 AS year,
    COUNT(DISTINCT a.consecutive_number) AS crashes
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`  AS a
  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`  AS d
    ON  a.state_number       = d.state_number
    AND a.consecutive_number = d.consecutive_number
  WHERE LOWER(d.driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
  GROUP BY a.state_name
),

rates AS (   -- compute rate per 100 000 residents
  SELECT
    d.year,
    d.state_name,
    d.crashes,
    p.pop_2010,
    ROUND(d.crashes * 100000.0 / p.pop_2010, 4) AS crashes_per_100k
  FROM distracted d
  JOIN pop        p USING (state_name)
),

ranked AS (   -- rank states within each year
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY year ORDER BY crashes_per_100k DESC) AS rnk
  FROM rates
)

SELECT
  year,
  state_name,
  crashes,
  pop_2010,
  crashes_per_100k
FROM ranked
WHERE rnk <= 5        -- top 5 states each year
ORDER BY year, crashes_per_100k DESC;