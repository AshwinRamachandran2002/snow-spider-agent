WITH state_daily_new AS (
  SELECT
    date,
    state_name,
    COALESCE(confirmed_cases 
             - LAG(confirmed_cases) OVER (PARTITION BY state_name ORDER BY date),
             confirmed_cases) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_states`
),
state_top5_per_day AS (
  SELECT
    date,
    state_name,
    new_cases
  FROM (
    SELECT
      date,
      state_name,
      new_cases,
      ROW_NUMBER() OVER (PARTITION BY date
                         ORDER BY new_cases DESC, state_name) AS rn
    FROM state_daily_new
    WHERE date BETWEEN '2020-03-01' AND '2020-05-31'
  )
  WHERE rn <= 5
),
state_frequency AS (
  SELECT
    state_name,
    COUNT(*) AS days_in_top5
  FROM state_top5_per_day
  GROUP BY state_name
),
state_ranking AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY days_in_top5 DESC, state_name) AS state_rank,
    state_name,
    days_in_top5
  FROM state_frequency
),
selected_state AS (
  SELECT state_name
  FROM state_ranking
  WHERE state_rank = 4      -- fourth‑place state overall
),
county_daily_new AS (
  SELECT
    c.date,
    c.state_name,
    c.county,
    c.county_fips_code,
    COALESCE(c.confirmed_cases
             - LAG(c.confirmed_cases) OVER (PARTITION BY c.county_fips_code ORDER BY c.date),
             c.confirmed_cases) AS new_cases
  FROM `bigquery-public-data.covid19_nyt.us_counties` c
),
county_top5_per_day AS (
  SELECT
    date,
    county,
    county_fips_code,
    new_cases
  FROM (
    SELECT
      cd.date,
      cd.county,
      cd.county_fips_code,
      cd.new_cases,
      ROW_NUMBER() OVER (PARTITION BY cd.date
                         ORDER BY cd.new_cases DESC, cd.county) AS rn
    FROM county_daily_new cd
    JOIN selected_state s
      ON cd.state_name = s.state_name
    WHERE cd.date BETWEEN '2020-03-01' AND '2020-05-31'
  )
  WHERE rn <= 5
),
county_frequency AS (
  SELECT
    county,
    county_fips_code,
    COUNT(*) AS days_in_state_top5
  FROM county_top5_per_day
  GROUP BY county, county_fips_code
),
county_ranking AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY days_in_state_top5 DESC, county) AS county_rank,
    county,
    days_in_state_top5
  FROM county_frequency
  ORDER BY county_rank
  LIMIT 5
)
SELECT
  'State Ranking (Mar–May 2020)'                                AS category,
  state_rank                                                    AS rank,
  state_name                                                    AS area,
  days_in_top5                                                  AS frequency
FROM state_ranking

UNION ALL

SELECT
  CONCAT('County Ranking for ', (SELECT state_name
                                 FROM selected_state),
         ' (Mar–May 2020)')                                     AS category,
  county_rank                                                   AS rank,
  county                                                        AS area,
  days_in_state_top5                                            AS frequency
FROM county_ranking

ORDER BY category, rank;