WITH distraction_vehicles AS (
  -- all vehicles whose drivers were reported as distracted (exclude “no / unknown”)
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, -4) AS INT64)         AS year,
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_*`
  WHERE _TABLE_SUFFIX IN ('2015','2016')
    AND driver_distracted_by_name NOT IN ('Not Distracted',
                                          'Unknown if Distracted',
                                          'Not Reported')
),
distraction_accidents AS (      -- one row per distracted crash
  SELECT DISTINCT year, state_number, consecutive_number
  FROM distraction_vehicles
),
all_accidents AS (              -- master accident list (to verify crashes exist)
  SELECT
    CAST(SUBSTR(_TABLE_SUFFIX, -4) AS INT64) AS year,
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_*`
  WHERE _TABLE_SUFFIX IN ('2015','2016')
),
distracted_crashes AS (         -- crashes that appear in both lists
  SELECT a.year, a.state_number
  FROM all_accidents AS a
  JOIN distraction_accidents AS d
    ON  a.year=d.year
    AND a.state_number=d.state_number
    AND a.consecutive_number=d.consecutive_number
),
-- map numeric state FIPS -> full state name
state_names AS (
  SELECT DISTINCT CAST(state_fips_code AS INT64) AS state_number,
         state_name
  FROM `bigquery-public-data.utility_us.us_states_area`
),
crash_counts AS (
  SELECT
    dc.year,
    sn.state_name,
    COUNT(*) AS distracted_crashes
  FROM distracted_crashes AS dc
  JOIN state_names  AS sn USING (state_number)
  GROUP BY dc.year, sn.state_name
),
-- 2010 population per state (sum of ZIP populations)
state_population AS (
  SELECT
    za.state_name,
    SUM(pb.population) AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS pb
  JOIN `bigquery-public-data.utility_us.zipcode_area`                AS za
    ON pb.zipcode = za.zipcode
  GROUP BY za.state_name
),
rates AS (
  SELECT
    cc.year,
    cc.state_name,
    cc.distracted_crashes,
    sp.population_2010,
    100000.0 * cc.distracted_crashes / sp.population_2010 AS crashes_per_100k
  FROM crash_counts      AS cc
  JOIN state_population  AS sp USING (state_name)
),
ranked AS (                     -- rank states by rate within each year
  SELECT
    year,
    state_name,
    crashes_per_100k,
    ROW_NUMBER() OVER (PARTITION BY year
                       ORDER BY crashes_per_100k DESC) AS rnk
  FROM rates
)
-- final answer: top‑5 states each year
SELECT
  year,
  state_name,
  ROUND(crashes_per_100k, 4)   AS crashes_per_100k
FROM ranked
WHERE rnk <= 5
ORDER BY year, crashes_per_100k DESC;