/* -----------------------------------------------------------
   Daily‑new‑case “top‑5” analysis  (Mar 1 – May 31 2020)
   Returns:
     • ranks 1‑5  – states that most frequently appear in the
                    nation‑wide daily‑top‑5 increases
     • ranks 6‑10 – counties (within the 4th‑ranked state) that most
                    frequently appear in that state’s daily‑top‑5
   Output columns: rank , state , days_in_daily_top5
   ----------------------------------------------------------- */
WITH
-- ----------  STATE‑LEVEL ----------
state_daily AS (
  SELECT
    date,
    state_name,
    confirmed_cases
      - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_top5_per_day AS (
  SELECT date, state_name
  FROM (
    SELECT
      date,
      state_name,
      ROW_NUMBER() OVER (PARTITION BY date
                         ORDER BY daily_new_cases DESC, state_name) AS rn
    FROM state_daily
    WHERE daily_new_cases IS NOT NULL
  )
  WHERE rn <= 5
),
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS days_in_daily_top5
  FROM state_top5_per_day
  GROUP BY state_name
),
state_ranked AS (
  SELECT
    state_name,
    days_in_daily_top5,
    ROW_NUMBER() OVER (ORDER BY days_in_daily_top5 DESC, state_name) AS rnk
  FROM state_frequency
),
state_top5 AS (
  SELECT *
  FROM state_ranked
  WHERE rnk <= 5
),

-- ----------  COUNTY‑LEVEL (for the 4th‑ranked state) ----------
target_state AS (
  SELECT state_name
  FROM state_top5
  WHERE rnk = 4
  LIMIT 1
),
county_daily AS (
  SELECT
    c.date,
    c.county,
    c.confirmed_cases
      - LAG(c.confirmed_cases) OVER (PARTITION BY c.county ORDER BY c.date) AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN target_state AS t
    ON c.state_name = t.state_name
  WHERE c.date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_top5_per_day AS (
  SELECT date, county
  FROM (
    SELECT
      date,
      county,
      ROW_NUMBER() OVER (PARTITION BY date
                         ORDER BY daily_new_cases DESC, county) AS rn
    FROM county_daily
    WHERE daily_new_cases IS NOT NULL
  )
  WHERE rn <= 5
),
county_frequency AS (
  SELECT
    county,
    COUNT(*) AS days_in_daily_top5
  FROM county_top5_per_day
  GROUP BY county
),
county_ranked AS (
  SELECT
    county,
    days_in_daily_top5,
    ROW_NUMBER() OVER (ORDER BY days_in_daily_top5 DESC, county) AS rnk
  FROM county_frequency
),
county_top5 AS (
  SELECT *
  FROM county_ranked
  WHERE rnk <= 5
)

-- ----------  FINAL RESULT ----------
SELECT
  rnk            AS rank,
  state_name     AS state,
  days_in_daily_top5
FROM state_top5

UNION ALL

SELECT
  rnk + 5        AS rank,      -- positions 6–10
  county         AS state,     -- keep column name “state” per spec
  days_in_daily_top5
FROM county_top5

ORDER BY rank;