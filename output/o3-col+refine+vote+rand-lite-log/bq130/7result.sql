WITH
/* ---------------------------------------------------------------------
   1)  Daily new-case counts for every U.S. state (Mar 1 – May 31 2020)
------------------------------------------------------------------------ */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date)  AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* ---------------------------------------------------------------------
   2)  The five highest-increase states for each day
------------------------------------------------------------------------ */
state_top5 AS (
  SELECT
    date,
    state_name
  FROM (
    SELECT
      date,
      state_name,
      daily_new_cases,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rn
    FROM state_daily
  )
  WHERE rn <= 5
),

/* ---------------------------------------------------------------------
   3)  How often each state appears in the daily top-five list
------------------------------------------------------------------------ */
state_tally AS (
  SELECT
    state_name,
    COUNT(*)                                           AS appearances_in_daily_top5,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC)        AS state_rank        -- 1 = most frequent
  FROM state_top5
  GROUP BY state_name
),

/* ---------------------------------------------------------------------
   4)  Grab the state that ranks 4th overall
------------------------------------------------------------------------ */
fourth_state AS (
  SELECT state_name
  FROM   state_tally
  WHERE  state_rank = 4
),

/* ---------------------------------------------------------------------
   5)  Daily new-case counts for every county inside that 4th-ranked state
------------------------------------------------------------------------ */
county_daily AS (
  SELECT
    c.date,
    c.county,
    c.confirmed_cases
      - LAG(c.confirmed_cases) OVER (PARTITION BY c.county ORDER BY c.date) AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN fourth_state f
  ON   c.state_name = f.state_name
  WHERE c.date BETWEEN '2020-03-01' AND '2020-05-31'
    AND c.county IS NOT NULL
    AND c.county <> 'Unknown'
),

/* ---------------------------------------------------------------------
   6)  Top-five counties (by daily increase) inside that state each day
------------------------------------------------------------------------ */
county_top5 AS (
  SELECT
    date,
    county
  FROM (
    SELECT
      date,
      county,
      daily_new_cases,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rn
    FROM county_daily
  )
  WHERE rn <= 5
),

/* ---------------------------------------------------------------------
   7)  How often each county appears in its state’s daily top five
------------------------------------------------------------------------ */
county_tally AS (
  SELECT
    county,
    COUNT(*)                                         AS appearances_in_state_top5,
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC)       AS county_rank       -- 1 = most frequent
  FROM county_top5
  GROUP BY county
  ORDER BY appearances_in_state_top5 DESC
  LIMIT 5                                            -- keep only the top-five counties
)

/* ---------------------------------------------------------------------
   8)  Final output:            • complete state ranking
                                • top-five counties for the 4th-ranked state
------------------------------------------------------------------------ */
SELECT
  'state'  AS level,
  state_name AS name,
  appearances_in_daily_top5 AS appearances,
  state_rank AS rank
FROM state_tally

UNION ALL

SELECT
  'county (within 4th-ranked state)' AS level,
  county  AS name,
  appearances_in_state_top5 AS appearances,
  county_rank AS rank
FROM county_tally

ORDER BY level, rank;