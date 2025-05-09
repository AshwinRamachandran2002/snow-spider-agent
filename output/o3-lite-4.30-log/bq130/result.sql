/* ----------------------------------------------------------
   1. Get each day’s TOP‑5 states by new cases (01 Mar – 31 May 2020)
      and count how often every state appears.
   2. Pick the 4th‑ranked state, then find each day’s TOP‑5 counties
      within that state and count their appearances.
   3. Return the two ranked lists (states first, then counties) in the
      format rank,state,days_in_daily_top5.
   ---------------------------------------------------------- */

WITH
/* ---------- state‑level daily new cases ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS daily_new
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date <= '2020-05-31'             -- keep all days up to end‑date so LAG works
),

/* top‑5 states for every day (Mar‑May 2020) */
state_top5_each_day AS (
  SELECT *
  FROM (
    SELECT
      date,
      state_name,
      daily_new,
      ROW_NUMBER() OVER (PARTITION BY date
                         ORDER BY daily_new DESC, state_name) AS rn
    FROM state_daily
    WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
  )
  WHERE rn <= 5
),

/* how many days each state is in that daily top‑5 */
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS days_in_top5
  FROM state_top5_each_day
  GROUP BY state_name
),

/* rank states by that frequency */
state_ranked AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY days_in_top5 DESC, state_name) AS rank,
    state_name,
    days_in_top5
  FROM state_frequency
),

/* keep the five most‑frequent states */
top_states AS (
  SELECT rank, state_name, days_in_top5
  FROM state_ranked
  WHERE rank <= 5
),

/* identify the 4th‑ranked state */
fourth_state AS (
  SELECT state_name
  FROM state_ranked
  WHERE rank = 4
),

/* ---------- county‑level daily new cases in that state ---------- */
county_daily AS (
  SELECT
    date,
    county,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY county ORDER BY date) AS daily_new
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE state_name IN (SELECT state_name FROM fourth_state)
    AND date <= '2020-05-31'
),

/* top‑5 counties (within that state) for every day */
county_top5_each_day AS (
  SELECT *
  FROM (
    SELECT
      date,
      county,
      state_name,
      daily_new,
      ROW_NUMBER() OVER (PARTITION BY date
                         ORDER BY daily_new DESC, county) AS rn
    FROM county_daily
    WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
  )
  WHERE rn <= 5
),

/* how many days each county is in that state‑level daily top‑5 */
county_frequency AS (
  SELECT
    county,
    state_name,
    COUNT(*) AS days_in_top5
  FROM county_top5_each_day
  GROUP BY county, state_name
),

/* take the five most‑frequent counties */
top_counties AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY days_in_top5 DESC, county) AS rank,
    CONCAT(county, ', ', state_name) AS state,
    days_in_top5
  FROM county_frequency
  ORDER BY rank
  LIMIT 5
),

/* ---------- build final output ---------- */
state_output AS (
  SELECT
    rank,
    state_name AS state,
    days_in_top5 AS days_in_daily_top5,
    0 AS grp                -- for ordering states before counties
  FROM top_states
),
county_output AS (
  SELECT
    rank,
    state,
    days_in_top5 AS days_in_daily_top5,
    1 AS grp
  FROM top_counties
)

SELECT
  rank,
  state,
  days_in_daily_top5
FROM (
  SELECT * FROM state_output
  UNION ALL
  SELECT * FROM county_output
)
ORDER BY grp, rank;