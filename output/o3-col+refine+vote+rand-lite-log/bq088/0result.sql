WITH period_avgs AS (
  -- 2019 calendar-year period: 01-Jan-2019 → 01-Jan-2020
  SELECT
    '2019' AS yr,
    AVG(SAFE_CAST(symptom_anxiety   AS FLOAT64))    AS avg_anxiety,
    AVG(SAFE_CAST(symptom_depression AS FLOAT64))  AS avg_depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND DATE(`date`) >= '2019-01-01'
    AND DATE(`date`) <  '2020-01-01'

  UNION ALL

  -- 2020 calendar-year period: 01-Jan-2020 → 01-Jan-2021
  SELECT
    '2020' AS yr,
    AVG(SAFE_CAST(symptom_anxiety   AS FLOAT64))    AS avg_anxiety,
    AVG(SAFE_CAST(symptom_depression AS FLOAT64))  AS avg_depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND DATE(`date`) >= '2020-01-01'
    AND DATE(`date`) <  '2021-01-01'
)

SELECT
  -- raw averages
  (SELECT avg_anxiety   FROM period_avgs WHERE yr = '2019') AS anxiety_2019,
  (SELECT avg_anxiety   FROM period_avgs WHERE yr = '2020') AS anxiety_2020,
  (SELECT avg_depression FROM period_avgs WHERE yr = '2019') AS depression_2019,
  (SELECT avg_depression FROM period_avgs WHERE yr = '2020') AS depression_2020,

  -- percentage changes
  100 * (
        (SELECT avg_anxiety FROM period_avgs WHERE yr = '2020') -
        (SELECT avg_anxiety FROM period_avgs WHERE yr = '2019')
      ) / (SELECT avg_anxiety FROM period_avgs WHERE yr = '2019') AS anxiety_pct_increase,

  100 * (
        (SELECT avg_depression FROM period_avgs WHERE yr = '2020') -
        (SELECT avg_depression FROM period_avgs WHERE yr = '2019')
      ) / (SELECT avg_depression FROM period_avgs WHERE yr = '2019') AS depression_pct_increase;