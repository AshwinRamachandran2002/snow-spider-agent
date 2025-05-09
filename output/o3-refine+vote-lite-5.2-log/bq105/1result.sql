/*  Driver‑distraction traffic accidents (fatal crashes)                     *
 *  – counts & rates per 100 000 population for each state, 2015‑2016        *
 *  – rate_rank_in_year lets you pick the 5 highest‑rate states each year    */

WITH state_lookup AS (     -- numeric FIPS  ↔︎ state name (publicly accessible)
  SELECT DISTINCT
         CAST(state_fips_code AS INT64) AS state_number,
         state_name
  FROM `bigquery-public-data.utility_us.us_states_area`
),

pop AS (                   -- 2010 Census population per state
  SELECT
    za.state_name,
    SUM(p.population) AS population_2010
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010` p
  JOIN `bigquery-public-data.utility_us.zipcode_area` za
    ON LPAD(p.zipcode,5,'0') = za.zipcode
  GROUP BY za.state_name
),

/* Vehicles whose drivers were recorded as distracted
   (exclude Not Distracted / Unknown / Not Reported)                        */
distracted_vehicle AS (
  SELECT
    2015 AS year,
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2015`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')

  UNION ALL

  SELECT
    2016 AS year,
    state_number,
    consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.distract_2016`
  WHERE LOWER(driver_distracted_by_name) NOT IN
        ('not distracted','unknown if distracted','not reported')
),

/* Distinct distraction‑related crashes per state & year                    */
accident_totals AS (
  SELECT
    year,
    state_number,
    COUNT(DISTINCT consecutive_number) AS distracted_accidents
  FROM distracted_vehicle
  GROUP BY year, state_number
),

/* Join to state names & population; compute rates & rankings               */
state_rates AS (
  SELECT
    a.year,
    sl.state_name,
    a.distracted_accidents,
    p.population_2010,
    SAFE_DIVIDE(a.distracted_accidents, p.population_2010) * 100000
        AS accidents_per_100k,
    RANK() OVER (PARTITION BY a.year
                 ORDER BY SAFE_DIVIDE(a.distracted_accidents, p.population_2010) DESC)
        AS rate_rank_in_year
  FROM accident_totals a
  JOIN state_lookup sl USING (state_number)
  JOIN pop           p USING (state_name)
)

SELECT
  year,
  state_name,
  distracted_accidents,
  population_2010,
  ROUND(accidents_per_100k, 4) AS accidents_per_100k,
  rate_rank_in_year
FROM state_rates
ORDER BY year, rate_rank_in_year, state_name;