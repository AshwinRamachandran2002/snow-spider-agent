/*  Driver‑distraction accident rates (per 100 000 residents) – 2015 & 2016  */
WITH population_2010 AS (      -- 2010 population aggregated from ZIP codes
  SELECT
    z.state_name,
    SUM(p.population) AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` p
  JOIN `bigquery-public-data.utility_us.zipcode_area` z
    ON LPAD(p.zipcode,5,'0') = z.zipcode
  WHERE z.state_name IS NOT NULL
  GROUP BY z.state_name
),
accidents_2015 AS (            -- distraction‑related accidents in 2015
  SELECT
    s.state_name,
    COUNT(DISTINCT d.consecutive_number) AS accidents_2015
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015` d
  JOIN `bigquery-public-data.utility_us.us_states_area` s
    ON LPAD(CAST(d.state_number AS STRING),2,'0') = s.state_fips_code
  WHERE LOWER(d.driver_distracted_by_name) NOT IN ('not distracted',
                                                   'unknown if distracted',
                                                   'not reported')
  GROUP BY s.state_name
),
accidents_2016 AS (            -- distraction‑related accidents in 2016
  SELECT
    s.state_name,
    COUNT(DISTINCT d.consecutive_number) AS accidents_2016
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016` d
  JOIN `bigquery-public-data.utility_us.us_states_area` s
    ON LPAD(CAST(d.state_number AS STRING),2,'0') = s.state_fips_code
  WHERE LOWER(d.driver_distracted_by_name) NOT IN ('not distracted',
                                                   'unknown if distracted',
                                                   'not reported')
  GROUP BY s.state_name
),
rates AS (                     -- accidents per 100 000 residents
  SELECT
    p.state_name                                                   AS state,
    ROUND(COALESCE(a15.accidents_2015,0) / p.population_2010 * 100000,4)
                                                                   AS accidents_per_100k_2015,
    ROUND(COALESCE(a16.accidents_2016,0) / p.population_2010 * 100000,4)
                                                                   AS accidents_per_100k_2016
  FROM population_2010 p
  LEFT JOIN accidents_2015 a15 ON p.state_name = a15.state_name
  LEFT JOIN accidents_2016 a16 ON p.state_name = a16.state_name
),
top5_2015 AS (                 -- top‑5 states in 2015
  SELECT state
  FROM rates
  ORDER BY accidents_per_100k_2015 DESC, state
  LIMIT 5
),
top5_2016 AS (                 -- top‑5 states in 2016
  SELECT state
  FROM rates
  ORDER BY accidents_per_100k_2016 DESC, state
  LIMIT 5
)
SELECT
  state,
  accidents_per_100k_2015,
  accidents_per_100k_2016,
  IF(state IN (SELECT state FROM top5_2015),'Y','N') AS in_top5_2015,
  IF(state IN (SELECT state FROM top5_2016),'Y','N') AS in_top5_2016
FROM rates
ORDER BY state;