/* -------------------------------------------------------------------------- *
 | 1)  Rank states by how often they appear in the nationwide daily “top-5”   |
 |     list of new COVID-19 cases (Mar-01–May-31 2020).                       |
 | 2)  Find the state that ranks 4th in that list.                            |
 | 3)  For that 4th–ranked state, rank its counties by how often they appear  |
 |     in the nationwide daily county-level “top-5” list over the same span. |
 |                                                                            |
 | The query returns two blocks of rows, distinguished by the “category”      |
 | column:                                                                    |
 |   • STATE_RANK   – state-level ranking                                     |
 |   • COUNTY_RANK_IN_4TH_STATE – county ranking inside the 4th-ranked state  |
 * -------------------------------------------------------------------------- */
WITH
-- Study window
date_window AS (
  SELECT DATE('2020-03-01') AS start_dt,
         DATE('2020-05-31') AS end_dt
),

/* ----------  STATE-LEVEL DAILY NEW CASES  ---------- */
state_daily AS (
  SELECT
    s.date,
    s.state_name,
    COALESCE(
      s.confirmed_cases
        - LAG(s.confirmed_cases) OVER (PARTITION BY s.state_name ORDER BY s.date),
      0
    ) AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states` AS s
  JOIN date_window w
    ON s.date BETWEEN w.start_dt AND w.end_dt
),

-- Top-5 states (by new cases) every day
state_top5 AS (
  SELECT date,
         state_name
  FROM (
    SELECT
      date,
      state_name,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rn
    FROM state_daily
  )
  WHERE rn <= 5
),

-- How many times each state appears in the daily top-5 list
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS times_in_top5
  FROM state_top5
  GROUP BY state_name
),

-- Rank states (1 = most frequent)
ranked_states AS (
  SELECT
    state_name,
    times_in_top5,
    DENSE_RANK() OVER (ORDER BY times_in_top5 DESC) AS state_rank
  FROM state_frequency
),

/* ----------  FOURTH-RANKED STATE  ---------- */
fourth_state AS (
  SELECT state_name
  FROM ranked_states
  WHERE state_rank = 4
  LIMIT 1
),

/* ----------  COUNTY-LEVEL DAILY NEW CASES  ---------- */
county_daily AS (
  SELECT
    c.date,
    c.county,
    c.state_name,
    COALESCE(
      c.confirmed_cases
        - LAG(c.confirmed_cases) OVER (PARTITION BY c.county_fips_code ORDER BY c.date),
      0
    ) AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN date_window w
    ON c.date BETWEEN w.start_dt AND w.end_dt
),

-- Top-5 counties (by new cases) every day
county_top5 AS (
  SELECT date,
         county,
         state_name
  FROM (
    SELECT
      date,
      county,
      state_name,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rn
    FROM county_daily
  )
  WHERE rn <= 5
),

-- How many times each county appears in the daily top-5 list
county_frequency AS (
  SELECT
    county,
    state_name,
    COUNT(*) AS times_in_top5
  FROM county_top5
  GROUP BY county, state_name
),

-- Restrict to counties inside the 4th-ranked state and rank them
ranked_counties AS (
  SELECT
    county,
    state_name,
    times_in_top5,
    ROW_NUMBER() OVER (ORDER BY times_in_top5 DESC) AS county_rank
  FROM county_frequency
  WHERE state_name = (SELECT state_name FROM fourth_state)
)

 /* ==================  FINAL OUTPUT  ================== */
SELECT
  'STATE_RANK'            AS category,
  state_rank              AS rank,
  state_name,
  times_in_top5           AS appearances,
  NULL                    AS county
FROM ranked_states

UNION ALL

SELECT
  'COUNTY_RANK_IN_4TH_STATE' AS category,
  county_rank                AS rank,
  state_name,
  times_in_top5              AS appearances,
  county
FROM ranked_counties
WHERE county_rank <= 5      -- top-5 counties
ORDER BY category, rank;