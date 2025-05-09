WITH pop_state AS (   -- 2010 Census population by state
  SELECT
    z.state_name,
    SUM(p.population) AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  JOIN `bigquery-public-data.utility_us.zipcode_area`                AS z
    ON LPAD(p.zipcode,5,'0') = z.zipcode            -- keep leading‑zero ZIPs
  GROUP BY z.state_name
),

distraction_accidents AS (          -- crashes that involve ANY distracted driver
  -- -------- 2015 --------
  SELECT
    2015 AS year,
    a.state_name,
    COUNT(DISTINCT a.consecutive_number) AS accident_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`  AS a
  JOIN (
        SELECT DISTINCT state_number, consecutive_number
        FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
        WHERE driver_distracted_by_name NOT IN
              ('Not Distracted','Unknown if Distracted','Not Reported')
       ) AS d
    ON a.state_number      = d.state_number
   AND a.consecutive_number = d.consecutive_number
  GROUP BY a.state_name

  UNION ALL

  -- -------- 2016 --------
  SELECT
    2016 AS year,
    a.state_name,
    COUNT(DISTINCT a.consecutive_number) AS accident_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`  AS a
  JOIN (
        SELECT DISTINCT state_number, consecutive_number
        FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
        WHERE driver_distracted_by_name NOT IN
              ('Not Distracted','Unknown if Distracted','Not Reported')
       ) AS d
    ON a.state_number      = d.state_number
   AND a.consecutive_number = d.consecutive_number
  GROUP BY a.state_name
),

rates AS (      -- accidents per 100 000 residents
  SELECT
    da.year,
    da.state_name,
    ROUND( da.accident_cnt * 100000.0 / ps.population_2010 , 4) AS acc_per_100k
  FROM distraction_accidents AS da
  JOIN pop_state            AS ps USING (state_name)
)

-- ----- top‑5 states each year -----
SELECT
  year,
  state_name,
  acc_per_100k
FROM rates
QUALIFY ROW_NUMBER() OVER (PARTITION BY year ORDER BY acc_per_100k DESC) <= 5
ORDER BY year, acc_per_100k DESC;