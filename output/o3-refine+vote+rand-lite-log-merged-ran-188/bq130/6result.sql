WITH
-- 1.  State-level daily new-case counts
state_daily_new AS (
  SELECT
    date,
    state_name,
    confirmed_cases
           - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS daily_new
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

-- 2.  For each day keep the five states with the largest increases
state_top5 AS (
  SELECT
    date,
    state_name
  FROM (
    SELECT
      date,
      state_name,
      DENSE_RANK() OVER (PARTITION BY date ORDER BY daily_new DESC) AS rnk
    FROM state_daily_new
  )
  WHERE rnk <= 5
),

-- 3.  How often does each state show up in the daily Top-5 list?
state_freq AS (
  SELECT
    state_name,
    COUNT(*) AS appearances
  FROM state_top5
  GROUP BY state_name
),

-- 4.  Rank the states by that frequency
ranked_states AS (
  SELECT
    state_name,
    appearances,
    ROW_NUMBER() OVER (ORDER BY appearances DESC, state_name) AS state_rank
  FROM state_freq
),

-- 5.  Identify the 4-th ranked state
target_state AS (
  SELECT state_name
  FROM ranked_states
  WHERE state_rank = 4
),

-- 6.  County-level daily new-case counts
county_daily_new AS (
  SELECT
    date,
    county,
    state_name,
    confirmed_cases
           - LAG(confirmed_cases) OVER (PARTITION BY county_fips_code ORDER BY date) AS daily_new
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),

-- 7.  Keep, for every day, the five counties with the largest increases
--     (restricted to the target state in the WHERE clause below)
county_top5 AS (
  SELECT
    date,
    county,
    state_name
  FROM (
    SELECT
      date,
      county,
      state_name,
      DENSE_RANK() OVER (PARTITION BY date ORDER BY daily_new DESC) AS rnk
    FROM county_daily_new
    WHERE state_name = (SELECT state_name FROM target_state)
  )
  WHERE rnk <= 5
),

-- 8.  How often does each county of the target state appear in the
--     nation-wide daily Top-5 county list?
county_freq AS (
  SELECT
    county,
    COUNT(*) AS appearances
  FROM county_top5
  GROUP BY county
),

-- 9.  Rank those counties
ranked_counties AS (
  SELECT
    (SELECT state_name FROM target_state) AS state_name,
    county,
    appearances,
    ROW_NUMBER() OVER (ORDER BY appearances DESC, county) AS county_rank
  FROM county_freq
)

-- 10.  Produce a single result set that shows:
--        • every state’s Top-5 appearance count and rank, and
--        • the Top-5 counties (within the 4-th-ranked state) by the same metric
SELECT
  'state'                           AS level,
  state_name                        AS state_or_county,
  NULL                              AS county,
  appearances,
  state_rank                        AS rank_within_level
FROM ranked_states

UNION ALL

SELECT
  'county'                          AS level,
  state_name                        AS state_or_county,
  county,
  appearances,
  county_rank                       AS rank_within_level
FROM ranked_counties
WHERE county_rank <= 5

ORDER BY
  level,           -- states first, then counties
  rank_within_level;