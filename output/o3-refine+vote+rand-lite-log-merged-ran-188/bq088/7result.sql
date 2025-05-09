WITH period_data AS (
  SELECT
    CASE
      WHEN `date` >= '2019-01-01' AND `date` < '2020-01-01' THEN '2019'
      WHEN `date` >= '2020-01-01' AND `date` < '2021-01-01' THEN '2020'
    END AS period,
    SAFE_CAST(symptom_anxiety    AS FLOAT64) AS anxiety,
    SAFE_CAST(symptom_depression AS FLOAT64) AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND `date` >= '2019-01-01'
    AND `date` <  '2021-01-01'
)
SELECT
  ROUND(AVG(CASE WHEN period = '2019' THEN anxiety END), 4) AS avg_anxiety_2019,
  ROUND(AVG(CASE WHEN period = '2020' THEN anxiety END), 4) AS avg_anxiety_2020,
  ROUND(
        100.0 * (
          AVG(CASE WHEN period = '2020' THEN anxiety END) -
          AVG(CASE WHEN period = '2019' THEN anxiety END)
        ) / AVG(CASE WHEN period = '2019' THEN anxiety END), 4
  ) AS anxiety_pct_increase,
  
  ROUND(AVG(CASE WHEN period = '2019' THEN depression END), 4) AS avg_depression_2019,
  ROUND(AVG(CASE WHEN period = '2020' THEN depression END), 4) AS avg_depression_2020,
  ROUND(
        100.0 * (
          AVG(CASE WHEN period = '2020' THEN depression END) -
          AVG(CASE WHEN period = '2019' THEN depression END)
        ) / AVG(CASE WHEN period = '2019' THEN depression END), 4
  ) AS depression_pct_increase
FROM period_data;