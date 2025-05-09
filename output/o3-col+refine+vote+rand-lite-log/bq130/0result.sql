/* -------------------------------------------------------------
   1)  Rank STATES by how often they appear in the DAILY Top-5
       for NEW Covid-19 cases   (1 Mar ‑ 31 May 2020).
   2)  Grab the state that ranks 4th overall and, inside that
       state, rank COUNTIES by how often they appear in that
       state’s DAILY Top-5 list of new cases (same period).
   3)  Return one result set that first lists ALL states with
       their ranks, then (labelled separately) the Top-5 counties
       for the 4-th ranked state.
----------------------------------------------------------------*/
WITH
/* ----------  STATE-LEVEL  ----------------------------------- */
state_new_cases AS (
  SELECT
    date,
    state_name,
    COALESCE(confirmed_cases
             - LAG(confirmed_cases)
               OVER (PARTITION BY state_name ORDER BY date),
             0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily_top5 AS (
  SELECT
    date,
    state_name
  FROM (
    SELECT
      date,
      state_name,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
    FROM state_new_cases
  )
  WHERE rn <= 5
),
state_appearances AS (
  SELECT
    state_name,
    COUNT(*) AS appearances_in_top5
  FROM state_daily_top5
  GROUP BY state_name
),
/* ----------  Identify 4-th ranked STATE  -------------------- */
fourth_state AS (
  SELECT state_name
  FROM state_appearances
  ORDER BY appearances_in_top5 DESC, state_name
  LIMIT 1 OFFSET 3                -- 0-based offset: 3 = 4th place
),
/* ----------  COUNTY-LEVEL (inside the 4-th state) ----------- */
county_new_cases AS (
  SELECT
    date,
    county,
    state_name,
    COALESCE(confirmed_cases
             - LAG(confirmed_cases)
               OVER (PARTITION BY state_name, county ORDER BY date),
             0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
    AND state_name = (SELECT state_name FROM fourth_state)
),
county_daily_top5 AS (
  SELECT
    date,
    county
  FROM (
    SELECT
      date,
      county,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rn
    FROM county_new_cases
  )
  WHERE rn <= 5
),
county_appearances AS (
  SELECT
    county,
    COUNT(*) AS appearances_in_top5
  FROM county_daily_top5
  GROUP BY county
),
/* ----------  Final RANKED lists ----------------------------- */
state_ranked AS (
  SELECT
    'state'                                  AS level,
    state_name                               AS name,
    appearances_in_top5,
    ROW_NUMBER() OVER (ORDER BY appearances_in_top5 DESC, state_name) AS rank
  FROM state_appearances
),
county_ranked AS (
  SELECT
    'county (in ' || (SELECT state_name FROM fourth_state) || ')' AS level,
    county                                        AS name,
    appearances_in_top5,
    ROW_NUMBER() OVER (ORDER BY appearances_in_top5 DESC, county) AS rank
  FROM county_appearances
  LIMIT 5
)

/* ----------  OUTPUT ---------------------------------------- */
SELECT *
FROM state_ranked

UNION ALL

SELECT *
FROM county_ranked
ORDER BY level, rank;