/* ----------------------------------------------------------
   1)  Identify, for every day from 1 Mar 2020–31 May 2020,
       the five states with the largest daily increases in
       confirmed COVID‑19 cases.
   2)  Rank states by how many times they appear in those
       daily top‑five lists and find the state that ranks 4th.
   3)  For that 4th–ranked state, repeat the procedure at the
       county level: count how often each of its counties is
       in the nationwide daily top‑five and list that state’s
       five most‑frequent counties.
   ---------------------------------------------------------- */

WITH
/* ----------  STATE‑LEVEL PART  ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    /* daily new cases; first day in window uses cumulative count */
    GREATEST(
      COALESCE(confirmed_cases -
               LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date),
               confirmed_cases),
      0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_top5_each_day AS (
  SELECT
    date,
    state_name,
    ROW_NUMBER() OVER (PARTITION BY date
                       ORDER BY new_cases DESC, state_name) AS rn
  FROM state_daily
),
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS days_in_top5
  FROM state_top5_each_day
  WHERE rn <= 5
  GROUP BY state_name
),
state_ranked AS (
  SELECT
    state_name,
    days_in_top5,
    DENSE_RANK() OVER (ORDER BY days_in_top5 DESC) AS state_rank
  FROM state_frequency
),
fourth_state AS (           -- keep the single 4th‑ranked state
  SELECT state_name
  FROM   state_ranked
  WHERE  state_rank = 4
  LIMIT  1
),

/* ----------  COUNTY‑LEVEL PART  ---------- */
county_daily AS (
  SELECT
    date,
    county,
    state_name,
    county_fips_code,
    GREATEST(
      COALESCE(confirmed_cases -
               LAG(confirmed_cases) OVER (PARTITION BY county_fips_code ORDER BY date),
               confirmed_cases),
      0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_top5_each_day AS (
  SELECT
    date,
    county,
    state_name,
    ROW_NUMBER() OVER (PARTITION BY date
                       ORDER BY new_cases DESC,
                                state_name,
                                county) AS rn
  FROM county_daily
),
county_frequency_in_4th_state AS (
  SELECT
    ct.county,
    ct.state_name,
    COUNT(*) AS days_in_top5
  FROM county_top5_each_day ct
  JOIN fourth_state fs
    ON ct.state_name = fs.state_name
  WHERE ct.rn <= 5                       -- nationwide daily top‑5 counties
  GROUP BY ct.county, ct.state_name
),
county_ranked AS (
  SELECT
    county,
    state_name,
    days_in_top5,
    DENSE_RANK() OVER (ORDER BY days_in_top5 DESC) AS county_rank
  FROM county_frequency_in_4th_state
)

/* ----------  FINAL RESULT  ---------- */
SELECT
  'state' AS level,
  state_name        AS name,
  days_in_top5      AS appearances_in_daily_top5,
  state_rank        AS rank_within_level
FROM state_ranked

UNION ALL

SELECT
  'county'                                             AS level,
  CONCAT(county, ', ', state_name)                     AS name,
  days_in_top5                                         AS appearances_in_daily_top5,
  county_rank                                          AS rank_within_level
FROM county_ranked
WHERE county_rank <= 5
ORDER BY level, rank_within_level;