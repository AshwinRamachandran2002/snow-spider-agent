-- 1) rank states by how often they are in the daily “top‑5” for new cases
-- 2) take the state that ranks 4th overall
-- 3) within that state, rank its counties by how often they are in the daily “top‑5”

WITH state_cumulative AS (
  SELECT
    date,
    state_name,
    confirmed_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily AS (
  SELECT
    date,
    state_name,
    COALESCE(confirmed_cases -
             LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date),
             confirmed_cases) AS new_cases
  FROM state_cumulative
),
state_top5_per_day AS (
  SELECT
    date,
    state_name,
    new_cases,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC, state_name) AS rn
  FROM state_daily
),
daily_top_states AS (
  SELECT date, state_name
  FROM state_top5_per_day
  WHERE rn <= 5
),
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS appearances
  FROM daily_top_states
  GROUP BY state_name
),
state_ranking AS (
  SELECT
    state_name,
    appearances,
    DENSE_RANK() OVER (ORDER BY appearances DESC, state_name) AS state_rank
  FROM state_frequency
),
target_state AS (
  SELECT state_name
  FROM state_ranking
  WHERE state_rank = 4
  LIMIT 1
),

-- --------------------  counties for 4th‑ranked state  --------------------
county_cumulative AS (
  SELECT
    date,
    county,
    state_name,
    county_fips_code,
    confirmed_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_daily AS (
  SELECT
    date,
    county,
    state_name,
    COALESCE(confirmed_cases -
             LAG(confirmed_cases) OVER (PARTITION BY county_fips_code ORDER BY date),
             confirmed_cases) AS new_cases
  FROM county_cumulative
),
target_state_daily AS (
  SELECT cd.*
  FROM county_daily cd
  JOIN target_state ts
    ON cd.state_name = ts.state_name
),
county_top5_per_day AS (
  SELECT
    date,
    county,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC, county) AS rn
  FROM target_state_daily
),
daily_top_counties AS (
  SELECT date, county
  FROM county_top5_per_day
  WHERE rn <= 5
),
county_frequency AS (
  SELECT
    county,
    COUNT(*) AS appearances
  FROM daily_top_counties
  GROUP BY county
),
county_ranking AS (
  SELECT
    county,
    appearances,
    DENSE_RANK() OVER (ORDER BY appearances DESC, county) AS county_rank
  FROM county_frequency
)

-- final combined output
SELECT
  'state_ranking' AS category,
  state_name  AS name,
  appearances,
  state_rank  AS rank
FROM state_ranking

UNION ALL

SELECT
  'county_ranking_for_state_' || (SELECT state_name FROM target_state) AS category,
  county      AS name,
  appearances,
  county_rank AS rank
FROM county_ranking
WHERE county_rank <= 5

ORDER BY category, rank;