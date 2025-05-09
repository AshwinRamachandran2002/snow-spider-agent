-- Calculate average weekly anxiety and depression levels for the U.S. in 2019 vs. 2020
WITH period_avgs AS (
  SELECT
    -- 2019 averages (2019-01-01 ≤ date < 2020-01-01)
    AVG(CASE
          WHEN date >= '2019-01-01' AND date < '2020-01-01'
          THEN SAFE_CAST(symptom_anxiety AS FLOAT64)
        END) AS avg_anxiety_2019,
    AVG(CASE
          WHEN date >= '2019-01-01' AND date < '2020-01-01'
          THEN SAFE_CAST(symptom_depression AS FLOAT64)
        END) AS avg_depression_2019,

    -- 2020 averages (2020-01-01 ≤ date < 2021-01-01)
    AVG(CASE
          WHEN date >= '2020-01-01' AND date < '2021-01-01'
          THEN SAFE_CAST(symptom_anxiety AS FLOAT64)
        END) AS avg_anxiety_2020,
    AVG(CASE
          WHEN date >= '2020-01-01' AND date < '2021-01-01'
          THEN SAFE_CAST(symptom_depression AS FLOAT64)
        END) AS avg_depression_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
)

SELECT
  ROUND(avg_anxiety_2019, 4)            AS avg_anxiety_2019,
  ROUND(avg_anxiety_2020, 4)            AS avg_anxiety_2020,
  ROUND(
    100 * (avg_anxiety_2020 - avg_anxiety_2019) / avg_anxiety_2019,
    4
  ) AS pct_increase_anxiety,
  ROUND(avg_depression_2019, 4)         AS avg_depression_2019,
  ROUND(avg_depression_2020, 4)         AS avg_depression_2020,
  ROUND(
    100 * (avg_depression_2020 - avg_depression_2019) / avg_depression_2019,
    4
  ) AS pct_increase_depression
FROM period_avgs;