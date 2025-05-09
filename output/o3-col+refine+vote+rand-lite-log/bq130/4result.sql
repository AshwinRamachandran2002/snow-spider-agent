/*  ----------------------------------------------------------
    1.  Rank states by how many times they appear in the daily
        top-5 list for NEW Covid-19 cases (Mar-May 2020)

    2.  Find the state(s) whose overall rank = 4

    3.  For that/those state(s), rank counties by how many times
        they appear in that state’s daily top-5 county list
        (again using NEW cases, Mar-May 2020)

    4.  Return one combined result set that shows
        • the state-level ranking
        • the top-5 counties for the 4-th-ranked state(s)
    ---------------------------------------------------------- */
WITH
/* ----------  State-level work  ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
daily_state_top5 AS (          -- 5 highest-increase states EACH day
  SELECT date, state_name
  FROM (
    SELECT
      date,
      state_name,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rnk
    FROM state_daily
  )
  WHERE rnk <= 5
),
state_rankings AS (            -- how often each state appears
  SELECT
    state_name,
    COUNT(*) AS appearances,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS overall_rank
  FROM daily_state_top5
  GROUP BY state_name
),
/* identify the 4-th ranked state(s) */
fourth_state AS (
  SELECT state_name
  FROM state_rankings
  WHERE overall_rank = 4
),

/* ----------  County-level work for the 4-th state  ---------- */
county_daily AS (
  SELECT
    c.date,
    c.state_name,
    c.county,
    c.county_fips_code,
    c.confirmed_cases
      - LAG(c.confirmed_cases) OVER (PARTITION BY c.county_fips_code ORDER BY c.date) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN fourth_state AS fs
    ON c.state_name = fs.state_name
  WHERE c.date BETWEEN '2020-03-01' AND '2020-05-31'
),
daily_county_top5 AS (         -- top-5 counties EACH day in that state
  SELECT date, county
  FROM (
    SELECT
      date,
      county,
      ROW_NUMBER() OVER (PARTITION BY date ORDER BY new_cases DESC) AS rnk
    FROM county_daily
    WHERE new_cases IS NOT NULL
  )
  WHERE rnk <= 5
),
county_rankings AS (           -- how often each county appears
  SELECT
    county,
    COUNT(*) AS appearances,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS county_rank
  FROM daily_county_top5
  GROUP BY county
  ORDER BY county_rank
  LIMIT 5                       -- keep top-5 counties
)

/* ----------  Final output  ---------- */
SELECT
  'state_rankings'      AS category,
  state_name            AS region,
  appearances,
  overall_rank
FROM state_rankings

UNION ALL

SELECT
  'county_rankings_of_rank4_state' AS category,
  county                           AS region,
  appearances,
  county_rank                      AS overall_rank
FROM county_rankings

ORDER BY category, overall_rank;