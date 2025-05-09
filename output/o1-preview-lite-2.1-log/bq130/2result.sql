WITH state_daily_new_cases AS (
  SELECT
    date,
    state_name,
    confirmed_cases - LAG(confirmed_cases) OVER (
      PARTITION BY state_name
      ORDER BY date
    ) AS daily_new_cases
  FROM
    `bigquery-public-data.covid19_nyt.us_states`
  WHERE
    date BETWEEN '2020-03-01' AND '2020-05-31'
),
state_daily_new_cases_non_negative AS (
  SELECT
    date,
    state_name,
    GREATEST(daily_new_cases, 0) AS daily_new_cases
  FROM
    state_daily_new_cases
),
top_states_per_day AS (
  SELECT
    date,
    state_name,
    daily_new_cases,
    ROW_NUMBER() OVER (
      PARTITION BY date
      ORDER BY daily_new_cases DESC
    ) AS state_rank
  FROM
    state_daily_new_cases_non_negative
),
state_top5_counts AS (
  SELECT
    state_name,
    COUNT(*) AS top5_appearances
  FROM
    top_states_per_day
  WHERE
    state_rank <= 5
  GROUP BY
    state_name
),
state_ranking AS (
  SELECT
    state_name,
    top5_appearances,
    DENSE_RANK() OVER (
      ORDER BY top5_appearances DESC
    ) AS state_overall_rank
  FROM
    state_top5_counts
),
fourth_ranked_state AS (
  SELECT
    state_name
  FROM
    state_ranking
  WHERE
    state_overall_rank = 4
),
county_daily_new_cases AS (
  SELECT
    date,
    county,
    confirmed_cases - LAG(confirmed_cases) OVER (
      PARTITION BY county
      ORDER BY date
    ) AS daily_new_cases
  FROM
    `bigquery-public-data.covid19_nyt.us_counties`
  WHERE
    state_name IN (SELECT state_name FROM fourth_ranked_state)
    AND date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_daily_new_cases_non_negative AS (
  SELECT
    date,
    county,
    GREATEST(daily_new_cases, 0) AS daily_new_cases
  FROM
    county_daily_new_cases
),
top_counties_per_day AS (
  SELECT
    date,
    county,
    daily_new_cases,
    ROW_NUMBER() OVER (
      PARTITION BY date
      ORDER BY daily_new_cases DESC
    ) AS county_rank
  FROM
    county_daily_new_cases_non_negative
),
county_top5_counts AS (
  SELECT
    county,
    COUNT(*) AS top5_appearances
  FROM
    top_counties_per_day
  WHERE
    county_rank <= 5
  GROUP BY
    county
)
SELECT
  county AS top_five_counties,
  top5_appearances AS count
FROM
  county_top5_counts
ORDER BY
  count DESC
LIMIT 5;