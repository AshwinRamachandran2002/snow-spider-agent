/*  Traffic-fatality distraction rates (per 100 K residents) by state,
    plus a ranking that identifies the five highest-rate states in 2015
    and 2016 (based on 2010 Census population).                              */

WITH pop AS (       -- 2010 Census population by state
  SELECT
    CAST(SUBSTR(LPAD(zipcode, 5, '0'), 1, 2) AS INT64) AS state_number,
    SUM(population) AS pop_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  GROUP BY state_number
),

distract_2015 AS (  -- 2015 distracted-driver crashes (unique crashes)
  SELECT
    state_number,
    COUNT(DISTINCT consecutive_number) AS crashes_2015
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted', 'unknown if distracted', 'not reported')
  GROUP BY state_number
),

distract_2016 AS (  -- 2016 distracted-driver crashes (unique crashes)
  SELECT
    state_number,
    COUNT(DISTINCT consecutive_number) AS crashes_2016
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted', 'unknown if distracted', 'not reported')
  GROUP BY state_number
),

rates AS (          -- crash rates per 100 000 population
  SELECT
    p.state_number,
    100000 * COALESCE(d15.crashes_2015, 0) / p.pop_2010 AS rate_2015,
    100000 * COALESCE(d16.crashes_2016, 0) / p.pop_2010 AS rate_2016
  FROM pop AS p
  LEFT JOIN distract_2015 AS d15 USING (state_number)
  LEFT JOIN distract_2016 AS d16 USING (state_number)
),

ranked AS (         -- rank states by rate in each year
  SELECT
    *,
    DENSE_RANK() OVER (ORDER BY rate_2015 DESC) AS rank_2015,
    DENSE_RANK() OVER (ORDER BY rate_2016 DESC) AS rank_2016
  FROM rates
)

SELECT
  state_number,
  ROUND(rate_2015, 4) AS crashes_per_100k_2015,
  ROUND(rate_2016, 4) AS crashes_per_100k_2016,
  rank_2015,
  rank_2016,
  CASE WHEN rank_2015 <= 5 THEN 'Yes' ELSE 'No' END AS top5_2015,
  CASE WHEN rank_2016 <= 5 THEN 'Yes' ELSE 'No' END AS top5_2016
FROM ranked
ORDER BY state_number;