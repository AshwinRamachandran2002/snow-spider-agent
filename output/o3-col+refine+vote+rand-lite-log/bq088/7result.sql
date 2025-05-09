-- Calculate average weekly anxiety & depression levels for the U.S. in 2019 vs 2020
WITH
-- 1-Jan-2019 → 1-Jan-2020
t19 AS (
  SELECT
    AVG(SAFE_CAST(symptom_anxiety    AS FLOAT64)) AS avg_anxiety_2019,
    AVG(SAFE_CAST(symptom_depression AS FLOAT64)) AS avg_depression_2019
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND DATE(date) >= '2019-01-01'
    AND DATE(date) <  '2020-01-01'
),
-- 1-Jan-2020 → 1-Jan-2021
t20 AS (
  SELECT
    AVG(SAFE_CAST(symptom_anxiety    AS FLOAT64)) AS avg_anxiety_2020,
    AVG(SAFE_CAST(symptom_depression AS FLOAT64)) AS avg_depression_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND DATE(date) >= '2020-01-01'
    AND DATE(date) <  '2021-01-01'
)

SELECT
  ROUND(t19.avg_anxiety_2019,    4) AS avg_anxiety_2019,
  ROUND(t19.avg_depression_2019, 4) AS avg_depression_2019,
  ROUND(t20.avg_anxiety_2020,    4) AS avg_anxiety_2020,
  ROUND(t20.avg_depression_2020, 4) AS avg_depression_2020,
  ROUND(100 * (t20.avg_anxiety_2020    - t19.avg_anxiety_2019)    / t19.avg_anxiety_2019,    4) AS pct_increase_anxiety,
  ROUND(100 * (t20.avg_depression_2020 - t19.avg_depression_2019) / t19.avg_depression_2019, 4) AS pct_increase_depression
FROM t19, t20;