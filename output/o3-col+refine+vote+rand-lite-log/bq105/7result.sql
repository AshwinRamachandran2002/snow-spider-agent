/*  Top-5 states with the highest rates of distraction–related fatal crashes
    (per 100,000 residents) in 2015 and 2016                            */

WITH zip_to_state AS (     -- ZIP-code-to-state look-up, keep only valid FIPS
  SELECT
    LPAD(zipcode,5,'0')                     AS zipcode,
    SAFE_CAST(state_fips AS INT64)          AS state_fips,
    state_name
  FROM `bigquery-public-data.utility_us.zipcode_area`
  WHERE SAFE_CAST(state_fips AS INT64) IS NOT NULL
),

state_population AS (      -- 2010 Census population by state
  SELECT
    zs.state_fips,
    zs.state_name,
    SUM(pb.population) AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` pb
  JOIN zip_to_state zs
    ON LPAD(pb.zipcode,5,'0') = zs.zipcode          -- pad 4-digit ZIPs
  GROUP BY zs.state_fips, zs.state_name
),

accident_counts AS (       -- distraction-related fatal crashes, by year/state
  SELECT
    2015                              AS year,
    state_number                      AS state_fips,
    COUNT(DISTINCT consecutive_number) AS crashes
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
  WHERE driver_distracted_by_name NOT IN ('Not Distracted',
                                          'Unknown if Distracted',
                                          'Not Reported')
  GROUP BY state_fips

  UNION ALL

  SELECT
    2016                              AS year,
    state_number                      AS state_fips,
    COUNT(DISTINCT consecutive_number) AS crashes
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
  WHERE driver_distracted_by_name NOT IN ('Not Distracted',
                                          'Unknown if Distracted',
                                          'Not Reported')
  GROUP BY state_fips
),

rates AS (                 -- crashes per 100,000 residents
  SELECT
    ac.year,
    sp.state_name,
    ROUND(ac.crashes * 100000.0 / sp.population_2010, 4) AS crashes_per_100k
  FROM accident_counts ac
  JOIN state_population sp
  ON ac.state_fips = sp.state_fips
),

ranked AS (                -- rank states within each year
  SELECT
    year,
    state_name,
    crashes_per_100k,
    DENSE_RANK() OVER (PARTITION BY year
                       ORDER BY crashes_per_100k DESC) AS rnk
  FROM rates
)

SELECT
  year,
  state_name,
  crashes_per_100k
FROM ranked
WHERE rnk <= 5
ORDER BY year, rnk;