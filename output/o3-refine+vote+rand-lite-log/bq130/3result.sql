/*-----------------------------------------------------------------------------
   1)  For every day from 2020‑03‑01 through 2020‑05‑31,
       find the five states with the largest DAILY increases
       in confirmed COVID‑19 cases.

   2)  Rank states by the number of times they appear in
       those daily “top‑5” lists.

   3)  Take the state that finishes 4‑th in that ranking and,
       within the same date range, repeat the exercise at the
       county level:  
       – each day find that state’s five counties with the
         largest daily increases,  
       – count how often each county appears,  
       – keep the five counties that appear most often.

   The query returns the two requested rankings together:
     • level = 'state'  – ranking of all states (frequency & rank)
     • level = 'county' – top‑5 counties for the 4‑th ranked state
-----------------------------------------------------------------------------*/
WITH
/* -----  State‑level daily new case counts  ------------------------------- */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases,
    LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS prev_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  -- grab one extra day (Feb‑29) so March‑01 has a previous value
  WHERE date BETWEEN '2020-02-29' AND '2020-05-31'
),
state_new_cases AS (
  SELECT
    date,
    state_name,
    COALESCE(confirmed_cases - prev_cases, confirmed_cases) AS new_cases
  FROM state_daily
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
/* -----  Top‑5 states each day by new cases  ------------------------------ */
state_daily_top5 AS (
  SELECT
    date,
    state_name,
    new_cases
  FROM (
    SELECT
      date,
      state_name,
      new_cases,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
    FROM state_new_cases
  )
  WHERE rn <= 5
),
/* -----  Frequency & overall ranking of states --------------------------- */
state_frequency AS (
  SELECT
    state_name,
    COUNT(*)                       AS freq,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC, state_name) AS state_rank
  FROM state_daily_top5
  GROUP BY state_name
),
/* -----  Identify the state that finished 4‑th --------------------------- */
fourth_state AS (
  SELECT state_name
  FROM   state_frequency
  WHERE  state_rank = 4
),
/* -----  County‑level daily new case counts for that state --------------- */
county_daily AS (
  SELECT
    c.date,
    c.county,
    c.state_name,
    c.confirmed_cases,
    LAG(c.confirmed_cases) OVER (
        PARTITION BY c.state_name, c.county ORDER BY c.date
    ) AS prev_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN fourth_state             AS fs
    ON c.state_name = fs.state_name
  WHERE c.date BETWEEN '2020-02-29' AND '2020-05-31'
),
county_new_cases AS (
  SELECT
    date,
    county,
    state_name,
    COALESCE(confirmed_cases - prev_cases, confirmed_cases) AS new_cases
  FROM county_daily
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
/* -----  Each day: that state’s five counties with largest increases ----- */
county_daily_top5 AS (
  SELECT
    date,
    county,
    state_name,
    new_cases
  FROM (
    SELECT
      date,
      county,
      state_name,
      new_cases,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
    FROM county_new_cases
  )
  WHERE rn <= 5
),
/* -----  Frequency & ranking of counties (keep top‑5) -------------------- */
county_frequency AS (
  SELECT
    county,
    state_name,
    COUNT(*) AS freq
  FROM county_daily_top5
  GROUP BY county, state_name
),
county_frequency_ranked AS (
  SELECT
    county,
    state_name,
    freq,
    ROW_NUMBER() OVER (ORDER BY freq DESC, county) AS county_rank
  FROM county_frequency
  ORDER BY freq DESC, county
  LIMIT 5
)

/* ======================  Final combined output  ========================= */
SELECT
  'state' AS level,
  state_name AS name,
  NULL      AS parent_state,
  freq,
  state_rank AS rank
FROM state_frequency

UNION ALL

SELECT
  'county' AS level,
  county   AS name,
  state_name AS parent_state,
  freq,
  county_rank AS rank
FROM county_frequency_ranked

ORDER BY
  level,          -- 'state' rows first, then 'county'
  rank;