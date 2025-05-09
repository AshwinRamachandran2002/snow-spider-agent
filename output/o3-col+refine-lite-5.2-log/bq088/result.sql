WITH period_2019 AS (
  SELECT
    AVG(CAST(`symptom_anxiety`    AS FLOAT64)) AS anxiety_2019,
    AVG(CAST(`symptom_depression` AS FLOAT64)) AS depression_2019
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE `country_region_code` = 'US'
    AND `date` >= '2019-01-01'
    AND `date` <  '2020-01-01'
),
period_2020 AS (
  SELECT
    AVG(CAST(`symptom_anxiety`    AS FLOAT64)) AS anxiety_2020,
    AVG(CAST(`symptom_depression` AS FLOAT64)) AS depression_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE `country_region_code` = 'US'
    AND `date` >= '2020-01-01'
    AND `date` <  '2021-01-01'
)
SELECT
  p19.anxiety_2019,
  p20.anxiety_2020,
  SAFE_DIVIDE(p20.anxiety_2020 - p19.anxiety_2019, p19.anxiety_2019) * 100
      AS anxiety_pct_increase,
  p19.depression_2019,
  p20.depression_2020,
  SAFE_DIVIDE(p20.depression_2020 - p19.depression_2019, p19.depression_2019) * 100
      AS depression_pct_increase
FROM period_2019 AS p19
CROSS JOIN period_2020 AS p20;