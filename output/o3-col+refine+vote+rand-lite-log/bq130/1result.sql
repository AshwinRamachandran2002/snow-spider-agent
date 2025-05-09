/*  ──────────────────────────────────────────────────────────────────────────
    1.  Rank states by how often they appear in the DAILY top-5 biggest jumps
        in confirmed COVID-19 cases, 01-Mar-2020 ⟶ 31-May-2020
    2.  Find the state that finishes 4th in that ranking
    3.  Within that state, rank counties the same way and keep the top five
    4.  Return one tidy result set with
          • the five highest-ranking states
          • the five highest-ranking counties in the 4th-place state
    ────────────────────────────────────────────────────────────────────────── */
WITH
/* ───── State-level daily new-case counts ───────────────────────────────── */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date)
        AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* Five biggest state jumps each day */
state_daily_ranked AS (
  SELECT
    date,
    state_name,
    daily_new_cases,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rn
  FROM state_daily
),
state_top5 AS (
  SELECT state_name
  FROM state_daily_ranked
  WHERE rn <= 5
),

/* How often does each state appear? */
state_rank AS (
  SELECT
    state_name,
    COUNT(*) AS appearances,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS overall_rank
  FROM state_top5
  GROUP BY state_name
),

/* 4th-ranked state */
fourth_state AS (
  SELECT state_name
  FROM state_rank
  WHERE overall_rank = 4
  LIMIT 1
),

/* ───── County-level daily new-case counts (only that state) ─────────────── */
county_daily AS (
  SELECT
    c.date,
    c.county,
    c.confirmed_cases
      - LAG(c.confirmed_cases) OVER (PARTITION BY c.county ORDER BY c.date)
        AS county_daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN fourth_state USING (state_name)
  WHERE c.date BETWEEN '2020-03-01' AND '2020-05-31'
),

/* Five biggest county jumps each day */
county_daily_ranked AS (
  SELECT
    date,
    county,
    county_daily_new_cases,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY county_daily_new_cases DESC)
      AS rn
  FROM county_daily
),
county_top5 AS (
  SELECT county
  FROM county_daily_ranked
  WHERE rn <= 5
),

/* How often does each county appear? */
county_rank AS (
  SELECT
    county,
    COUNT(*) AS appearances_in_daily_top5,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS county_rank
  FROM county_top5
  GROUP BY county
)

/* ───── Final combined answer ───────────────────────────────────────────── */
SELECT
  'state'                                   AS level,
  state_name                                AS name,
  appearances                               AS frequency,
  overall_rank                              AS rank
FROM state_rank
WHERE overall_rank <= 5

UNION ALL

SELECT
  'county'                                  AS level,
  county                                    AS name,
  appearances_in_daily_top5                 AS frequency,
  county_rank                               AS rank
FROM county_rank AS cr
WHERE cr.county_rank <= 5

ORDER BY level, rank;