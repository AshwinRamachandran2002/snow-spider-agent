/* ------------------------------------------------------------
   1)  Count, for every day from 2020‑03‑01 to 2020‑05‑31,
       the five states with the largest daily increases in
       confirmed cases.

   2)  Rank states by how often they appear in those daily
       top‑fives.

   3)  Take the state that ranks 4th overall and, within the
       same date‑range, determine which of its counties appear
       most frequently in their own daily top‑five lists for
       new cases.

   4)  Return one result set that contains:
           • the state‑level ranking, and
           • the county‑level ranking for the 4th‑ranked state
---------------------------------------------------------------- */
WITH
/* ---------- daily new cases for every state ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - COALESCE(LAG(confirmed_cases)
                 OVER (PARTITION BY state_name ORDER BY date),0)
      AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
),

/* ---------- top‑5 states for each day ---------- */
state_top5_each_day AS (
  SELECT
    date,
    state_name,
    new_cases,
    DENSE_RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rank_in_day
  FROM state_daily
  WHERE date BETWEEN DATE('2020-03-01') AND DATE('2020-05-31')
),

/* ---------- how many times each state appeared in a daily top‑5 ---------- */
state_freq AS (
  SELECT
    state_name,
    COUNTIF(rank_in_day<=5) AS appearances
  FROM state_top5_each_day
  GROUP BY state_name
),

/* ---------- overall state ranking ---------- */
state_ranked AS (
  SELECT
    state_name,
    appearances,
    DENSE_RANK() OVER (ORDER BY appearances DESC, state_name) AS state_rank
  FROM state_freq
),

/* ---------- identify the 4th‑ranked state ---------- */
fourth_state AS (
  SELECT state_name
  FROM state_ranked
  WHERE state_rank = 4
  LIMIT 1
),

/* ---------- daily new cases for every county ---------- */
county_daily AS (
  SELECT
    date,
    state_name,
    county,
    confirmed_cases
      - COALESCE(LAG(confirmed_cases)
                 OVER (PARTITION BY state_name, county ORDER BY date),0)
      AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
),

/* ---------- keep only counties in the 4th‑ranked state and date window ---------- */
county_filtered AS (
  SELECT
    date,
    county,
    new_cases
  FROM county_daily
  WHERE state_name = (SELECT state_name FROM fourth_state)
    AND date BETWEEN DATE('2020-03-01') AND DATE('2020-05-31')
),

/* ---------- that state’s top‑5 counties each day ---------- */
county_top5_each_day AS (
  SELECT
    date,
    county,
    new_cases,
    DENSE_RANK() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rank_in_day
  FROM county_filtered
),

/* ---------- how often each county appeared in a daily top‑5 ---------- */
county_freq AS (
  SELECT
    county,
    COUNTIF(rank_in_day<=5) AS appearances
  FROM county_top5_each_day
  GROUP BY county
),

/* ---------- overall county ranking for the 4th‑ranked state ---------- */
county_ranked AS (
  SELECT
    county,
    appearances,
    DENSE_RANK() OVER (ORDER BY appearances DESC, county) AS county_rank
  FROM county_freq
)

/* ---------- final combined result ---------- */
SELECT
  'state'                           AS level,
  state_name                        AS name,
  appearances,
  state_rank                        AS rank
FROM state_ranked

UNION ALL

SELECT
  'county_of_state_rank_4'          AS level,
  county                            AS name,
  appearances,
  county_rank                       AS rank
FROM county_ranked
ORDER BY level, rank;