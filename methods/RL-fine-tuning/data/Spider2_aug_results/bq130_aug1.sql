-- Task: Identify how many times each state appeared in the top five states by daily new COVID-19 cases from March to May 2020.

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
)
SELECT
  state_name,
  top5_count
FROM state_top5_counts
ORDER BY top5_count DESC;