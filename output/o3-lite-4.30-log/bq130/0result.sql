/* -----------------------------------------------------------------
   DAILY‑TOP‑5 ANALYSIS  (2020‑03‑01 → 2020‑05‑31)

   1)  Rank U.S. states by the number of days they appear in the
       national top‑5 for NEW Covid‑19 cases.
   2)  For the state that finishes 4th in that ranking, list the
       five counties that most frequently appear in that state’s
       own daily top‑5 list of NEW cases.
   ---------------------------------------------------------------- */
WITH
/* ---------- 1.   STATE‑LEVEL WORK  ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_ranked AS (
  SELECT
    date,
    state_name,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
  FROM state_daily
  WHERE new_cases IS NOT NULL
),
state_frequency AS (
  SELECT
    state_name,
    COUNTIF(rn <= 5) AS days_in_daily_top5
  FROM state_ranked
  GROUP BY state_name
),
ordered_states AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY days_in_daily_top5 DESC, state_name) AS rank,
    state_name,
    days_in_daily_top5
  FROM state_frequency
),

/* ---------- 2.   IDENTIFY 4th‑PLACE STATE  ---------- */
target_state AS (
  SELECT state_name
  FROM ordered_states
  WHERE rank = 4
),

/* ---------- 3.   COUNTY‑LEVEL WORK FOR THAT STATE  ---------- */
county_daily AS (
  SELECT
    c.date,
    c.county,
    c.confirmed_cases
      - LAG(c.confirmed_cases) OVER (PARTITION BY c.county ORDER BY c.date) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN target_state
    ON c.state_name = target_state.state_name
  WHERE c.date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_ranked AS (
  SELECT
    date,
    county,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
  FROM county_daily
  WHERE new_cases IS NOT NULL
),
county_frequency AS (
  SELECT
    county,
    COUNTIF(rn <= 5) AS days_in_daily_top5
  FROM county_ranked
  GROUP BY county
  ORDER BY days_in_daily_top5 DESC, county
  LIMIT 5
)

/* ---------- 4.   FINAL OUTPUT  ----------
     • First section: state ranking   (rank,state,days_in_daily_top5)
     • Second section: county ranking (NULL,county,days_in_daily_top5)            */
SELECT
  CAST(rank AS STRING)        AS rank,
  state_name                  AS state,
  days_in_daily_top5
FROM ordered_states

UNION ALL

SELECT
  NULL                        AS rank,
  county                      AS state,
  days_in_daily_top5
FROM county_frequency;