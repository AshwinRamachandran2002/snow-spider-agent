WITH daily_state_cases AS (
  SELECT
    date,
    state_name,
    confirmed_cases,
    LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS prev_day_cases,
    confirmed_cases - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date) AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
  WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily_top5 AS (
  SELECT
    date,
    state_name,
    daily_new_cases,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rank
  FROM daily_state_cases
  WHERE prev_day_cases IS NOT NULL
),
state_top5 AS (
  SELECT
    date,
    state_name,
    daily_new_cases
  FROM state_daily_top5
  WHERE rank <= 5
),
state_top5_counts AS (
  SELECT
    state_name,
    COUNT(*) AS top5_count
  FROM state_top5
  GROUP BY state_name
),
state_ranking AS (
  SELECT
    state_name,
    top5_count,
    DENSE_RANK() OVER (ORDER BY top5_count DESC) AS rank
  FROM state_top5_counts
),
state_fourth AS (
  SELECT state_name
  FROM state_ranking
  WHERE rank = 4
),
daily_county_cases AS (
  SELECT
    date,
    county,
    state_name,
    confirmed_cases,
    LAG(confirmed_cases) OVER (PARTITION BY state_name, county ORDER BY date) AS prev_day_cases,
    confirmed_cases - LAG(confirmed_cases) OVER (PARTITION BY state_name, county ORDER BY date) AS daily_new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties`
  WHERE state_name IN (SELECT state_name FROM state_fourth)
    AND date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_daily_top5 AS (
  SELECT
    date,
    county,
    daily_new_cases,
    ROW_NUMBER() OVER (PARTITION BY date ORDER BY daily_new_cases DESC) AS rank
  FROM daily_county_cases
  WHERE prev_day_cases IS NOT NULL
),
county_top5 AS (
  SELECT
    date,
    county,
    daily_new_cases
  FROM county_daily_top5
  WHERE rank <= 5
),
county_top5_counts AS (
  SELECT
    county,
    COUNT(*) AS top5_count
  FROM county_top5
  GROUP BY county
)
SELECT
  county AS top_five_counties,
  top5_count AS count
FROM county_top5_counts
ORDER BY count DESC
LIMIT 5;