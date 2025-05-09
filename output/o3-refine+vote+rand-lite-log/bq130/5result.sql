-- 1)  Build the daily TOP‑5 states by NEW cases from 1‑Mar‑2020 to 31‑May‑2020,
-- 2)  Rank states by how often they appear in that daily TOP‑5 list,
-- 3)  Take the state that ranks 4th in that list,
-- 4)  For that state, build the daily TOP‑5 counties by NEW cases for the same period,
-- 5)  Rank its counties by how often they appear in that daily county TOP‑5 list,
-- 6)  Return both rankings in one result set
WITH
/* ----------  STATE–LEVEL DAILY NEW CASES  ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
           - IFNULL(LAG(confirmed_cases)
                     OVER (PARTITION BY state_name ORDER BY date),0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-02-29' AND '2020-05-31'          -- include day before window for LAG
),
state_daily_window AS (
  SELECT * 
  FROM state_daily
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
daily_state_top5 AS (
  SELECT
    date,
    state_name,
    new_cases,
    RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rnk
  FROM state_daily_window
),
state_top5_filtered AS (
  SELECT date, state_name           -- keep only the TOP‑5 per day
  FROM daily_state_top5
  WHERE rnk <= 5
),
/* ----------  STATE RANKING BY FREQUENCY  ---------- */
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS appearances
  FROM state_top5_filtered
  GROUP BY state_name
),
state_ranking AS (
  SELECT
    state_name,
    appearances,
    DENSE_RANK() OVER (ORDER BY appearances DESC) AS state_rank
  FROM state_frequency
),
fourth_state AS (
  SELECT state_name
  FROM state_ranking
  WHERE state_rank = 4
  LIMIT 1
),
/* ----------  COUNTY–LEVEL DAILY NEW CASES FOR THE 4TH STATE  ---------- */
county_daily AS (
  SELECT
    c.date,
    c.state_name,
    c.county,
    c.county_fips_code,
    c.confirmed_cases
      - IFNULL(LAG(c.confirmed_cases)
               OVER (PARTITION BY c.county_fips_code ORDER BY c.date),0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN fourth_state AS fs
  ON c.state_name = fs.state_name
  WHERE c.date BETWEEN '2020-02-29' AND '2020-05-31'
),
county_daily_window AS (
  SELECT * 
  FROM county_daily
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
daily_county_top5 AS (
  SELECT
    date,
    county,
    state_name,
    new_cases,
    RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rnk
  FROM county_daily_window
),
county_top5_filtered AS (
  SELECT date, county, state_name
  FROM daily_county_top5
  WHERE rnk <= 5
),
/* ----------  COUNTY RANKING BY FREQUENCY  ---------- */
county_frequency AS (
  SELECT
    county,
    state_name,
    COUNT(*) AS appearances
  FROM county_top5_filtered
  GROUP BY county, state_name
),
county_ranking AS (
  SELECT
    county,
    state_name,
    appearances,
    ROW_NUMBER() OVER (ORDER BY appearances DESC, county) AS county_rank
  FROM county_frequency
  ORDER BY appearances DESC
  LIMIT 5
)

/* ----------  FINAL RESULT  ---------- */
SELECT
  'state' AS level,
  state_rank AS rank,
  state_name AS name,
  appearances AS frequency
FROM state_ranking

UNION ALL

SELECT
  'county' AS level,
  county_rank AS rank,
  CONCAT(county, ', ', state_name) AS name,
  appearances AS frequency
FROM county_ranking

ORDER BY
  level,
  rank;