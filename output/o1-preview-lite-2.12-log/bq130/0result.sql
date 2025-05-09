WITH daily_state_cases AS (
  SELECT
    date,
    state_name,
    confirmed_cases,
    LAG(confirmed_cases) OVER (
      PARTITION BY state_name
      ORDER BY date
    ) AS prev_confirmed_cases
  FROM
    `bigquery-public-data.covid19_nyt.us_states`
  WHERE
    date BETWEEN '2020-03-01' AND '2020-05-31'
),
daily_new_state_cases AS (
  SELECT
    date,
    state_name,
    IFNULL(confirmed_cases - prev_confirmed_cases, confirmed_cases) AS daily_new_cases
  FROM
    daily_state_cases
),
state_daily_top5 AS (
  SELECT
    date,
    state_name,
    daily_new_cases,
    ROW_NUMBER() OVER (
      PARTITION BY date
      ORDER BY daily_new_cases DESC
    ) AS state_rank
  FROM
    daily_new_state_cases
),
state_top_counts AS (
  SELECT
    state_name,
    COUNT(*) AS top5_count
  FROM
    state_daily_top5
  WHERE
    state_rank <= 5
  GROUP BY
    state_name
),
state_rankings AS (
  SELECT
    state_name,
    top5_count,
    ROW_NUMBER() OVER (
      ORDER BY top5_count DESC
    ) AS state_rank
  FROM
    state_top_counts
),
fourth_state AS (
  SELECT
    state_name
  FROM
    state_rankings
  WHERE
    state_rank = 4
),
county_daily_cases AS (
  SELECT
    c.date,
    c.county,
    c.confirmed_cases,
    LAG(c.confirmed_cases) OVER (
      PARTITION BY c.county
      ORDER BY c.date
    ) AS prev_confirmed_cases
  FROM
    `bigquery-public-data.covid19_nyt.us_counties` AS c
  JOIN
    fourth_state AS fs
    ON c.state_name = fs.state_name
  WHERE
    c.date BETWEEN '2020-03-01' AND '2020-05-31'
),
county_daily_new_cases AS (
  SELECT
    date,
    county,
    IFNULL(confirmed_cases - prev_confirmed_cases, confirmed_cases) AS daily_new_cases
  FROM
    county_daily_cases
),
county_daily_top5 AS (
  SELECT
    date,
    county,
    daily_new_cases,
    ROW_NUMBER() OVER (
      PARTITION BY date
      ORDER BY daily_new_cases DESC
    ) AS county_rank
  FROM
    county_daily_new_cases
),
county_top_counts AS (
  SELECT
    county,
    COUNT(*) AS top5_count
  FROM
    county_daily_top5
  WHERE
    county_rank <= 5
  GROUP BY
    county
  ORDER BY
    top5_count DESC
)
SELECT
  county AS top_five_counties,
  top5_count AS count
FROM
  county_top_counts
LIMIT 5;