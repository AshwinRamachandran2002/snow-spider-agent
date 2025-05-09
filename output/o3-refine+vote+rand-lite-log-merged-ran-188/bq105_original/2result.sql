/*  Driver–distraction crash rates (per 100 000 residents, 2010 Census pop.)
    Top‑5 states for 2015 and 2016                                          */

WITH state_xwalk AS (                -- FIPS → state name (public table)
  SELECT DISTINCT
    CAST(state_fips_code AS INT64)  AS state_number,
    state_name
  FROM `bigquery-public-data.utility_us.us_states_area`
),

pop_state AS (                       -- 2010 population by state
  SELECT
    za.state_name,
    SUM(pb.population) AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` pb
  JOIN `bigquery-public-data.utility_us.zipcode_area` za
    ON LPAD(pb.zipcode,5,'0') = za.zipcode            -- keep leading zeros
  GROUP BY za.state_name
),

distracted_crashes AS (              -- crashes with a distracted driver
  SELECT
    2015        AS year,
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')

  UNION ALL

  SELECT
    2016        AS year,
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
),

accidents_by_state_year AS (         -- distinct crashes per state & year
  SELECT
    year,
    state_number,
    COUNT(DISTINCT consecutive_number) AS distracted_accidents
  FROM distracted_crashes
  GROUP BY year, state_number
),

rates AS (                           -- rate per 100 000 residents
  SELECT
    a.year,
    sx.state_name,
    a.distracted_accidents,
    p.population_2010,
    1.0 * a.distracted_accidents / p.population_2010 * 100000
        AS accidents_per_100k
  FROM accidents_by_state_year a
  JOIN state_xwalk  sx USING (state_number)
  JOIN pop_state    p USING (state_name)
),

ranked AS (                          -- rank states each year
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY year
                       ORDER BY accidents_per_100k DESC) AS rn
  FROM rates
)

SELECT
  year,
  state_name,
  ROUND(accidents_per_100k,4) AS accidents_per_100k
FROM ranked
WHERE rn <= 5
ORDER BY year, accidents_per_100k DESC;