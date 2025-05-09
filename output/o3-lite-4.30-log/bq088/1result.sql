WITH base AS (
  SELECT
    'anxiety' AS metric,
    SAFE_CAST(`symptom_anxiety` AS FLOAT64) AS value,
    DATE(`date`) AS dt
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE `country_region_code` = 'US'
  
  UNION ALL
  
  SELECT
    'depression' AS metric,
    SAFE_CAST(`symptom_depression` AS FLOAT64) AS value,
    DATE(`date`) AS dt
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE `country_region_code` = 'US'
),
period_avgs AS (
  SELECT
    metric,
    AVG(IF(dt >= '2019-01-01' AND dt < '2020-01-01', value, NULL)) AS average_2019,
    AVG(IF(dt >= '2020-01-01' AND dt < '2021-01-01', value, NULL)) AS average_2020
  FROM base
  WHERE dt >= '2019-01-01' AND dt < '2021-01-01'
  GROUP BY metric
)
SELECT
  metric,
  ROUND(average_2019, 4) AS average_2019,
  ROUND(average_2020, 4) AS average_2020,
  ROUND(100 * (average_2020 - average_2019) / average_2019, 4) AS percentage_increase
FROM period_avgs
ORDER BY metric;