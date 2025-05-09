-- Top‑five states by daily new‑case surges (Mar–May 2020) and,
-- for the state that ranks 4th by frequency, its top‑five counties
WITH
/* ----------  DAILY NEW CASES BY STATE  ---------- */
state_daily AS (
  SELECT
    date,
    state_name,
    IFNULL(confirmed_cases -
            LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date),
           0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
),
state_daily_window AS (
  SELECT
    date,
    state_name,
    new_cases,
    ROW_NUMBER() OVER (PARTITION BY date
                       ORDER BY new_cases DESC, state_name) AS rn
  FROM state_daily
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_freq AS (
  SELECT
    state_name,
    COUNT(*)         AS appearances
  FROM state_daily_window
  WHERE rn <= 5                       -- top‑five for each day
  GROUP BY state_name
),
/* identify the state(s) ranked 4th by appearances */
fourth_state AS (
  SELECT state_name
  FROM (
    SELECT
      state_name,
      appearances,
      DENSE_RANK() OVER (ORDER BY appearances DESC) AS freq_rank
    FROM state_freq
  )
  WHERE freq_rank = 4
),

/* ----------  DAILY NEW CASES BY COUNTY  ---------- */
county_daily AS (
  SELECT
    date,
    county_fips_code,
    county,
    state_name,
    IFNULL(confirmed_cases -
            LAG(confirmed_cases) OVER (PARTITION BY county_fips_code ORDER BY date),
           0) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
),
county_daily_window AS (
  SELECT
    date,
    county_fips_code,
    county,
    state_name,
    new_cases,
    ROW_NUMBER() OVER (PARTITION BY date
                       ORDER BY new_cases DESC,
                                state_name,
                                county) AS rn
  FROM county_daily
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_freq AS (
  SELECT
    county,
    state_name,
    COUNT(*) AS appearances
  FROM county_daily_window
  WHERE rn <= 5                       -- top‑five for each day
  GROUP BY county, state_name
),
county_freq_fourth_state AS (
  SELECT *
  FROM county_freq
  WHERE state_name IN (SELECT state_name FROM fourth_state)
  ORDER BY appearances DESC, county
  LIMIT 5
)

/* ----------  FINAL COMBINED OUTPUT  ---------- */
SELECT
  'state' AS level,
  state_name                     AS location,
  appearances
FROM state_freq
UNION ALL
SELECT
  'county' AS level,
  CONCAT(county, ', ', state_name) AS location,
  appearances
FROM county_freq_fourth_state
ORDER BY level, appearances DESC, location;