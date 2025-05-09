/*  Driver–distraction accident rates (per 100 000 residents) for 2015 & 2016,
    ranked within each year (rank 1 = highest rate).
    “Distracted” excludes:  Not Distracted, Unknown if Distracted, Not Reported  */

WITH state_lookup AS (               -- FIPS → full state name (open dataset)
  SELECT
    CAST(state_fips_code AS INT64)          AS state_number,
    MAX(state_name)                         AS state_name
  FROM `bigquery-public-data.utility_us.us_states_area`
  GROUP BY state_number
),

pop_state AS (                        -- 2010 Census population by state
  SELECT
    za.state_name,
    SUM(p.population)                 AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` p
  JOIN `bigquery-public-data.utility_us.zipcode_area` za
    ON LPAD(p.zipcode,5,'0') = za.zipcode
  GROUP BY za.state_name
),

distract_year AS (                    -- fatal‑crash cases w/ ≥1 distracted driver
  SELECT
    state_number,
    2015 AS year,
    COUNT(DISTINCT CONCAT(state_number,'-',consecutive_number)) AS accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
  GROUP BY state_number
  
  UNION ALL
  
  SELECT
    state_number,
    2016 AS year,
    COUNT(DISTINCT CONCAT(state_number,'-',consecutive_number)) AS accidents
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
  GROUP BY state_number
),

distracted_acc AS (
  SELECT
    sl.state_name,
    dy.year,
    dy.accidents
  FROM distract_year  dy
  JOIN state_lookup   sl USING (state_number)
),

rates AS (                            -- accidents per 100 000 residents
  SELECT
    da.year,
    da.state_name,
    da.accidents,
    ps.population_2010,
    da.accidents * 100000.0 / ps.population_2010 AS accidents_per_100k
  FROM distracted_acc da
  JOIN pop_state     ps USING (state_name)
),

ranked AS (                           -- rank states within each year
  SELECT
    year,
    state_name,
    ROUND(accidents_per_100k,4) AS accidents_per_100k,
    ROW_NUMBER() OVER (PARTITION BY year
                       ORDER BY accidents_per_100k DESC) AS state_rank
  FROM rates
)

SELECT
  *
FROM ranked
ORDER BY
  year,
  state_rank;