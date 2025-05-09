-- Average weekly anxiety & depression for the U.S. in 2019 vs 2020
WITH
period_2019 AS (
  SELECT
    AVG(SAFE_CAST(symptom_anxiety    AS FLOAT64)) AS anxiety_2019,
    AVG(SAFE_CAST(symptom_depression AS FLOAT64)) AS depression_2019
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND date >= '2019-01-01' 
    AND date <  '2020-01-01'
),
period_2020 AS (
  SELECT
    AVG(SAFE_CAST(symptom_anxiety    AS FLOAT64)) AS anxiety_2020,
    AVG(SAFE_CAST(symptom_depression AS FLOAT64)) AS depression_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND date >= '2020-01-01' 
    AND date <  '2021-01-01'
)
SELECT
  ROUND(anxiety_2019,     4) AS avg_anxiety_2019,
  ROUND(anxiety_2020,     4) AS avg_anxiety_2020,
  ROUND(100 * (anxiety_2020   - anxiety_2019)   / anxiety_2019, 4) AS anxiety_pct_increase,
  ROUND(depression_2019,  4) AS avg_depression_2019,
  ROUND(depression_2020,  4) AS avg_depression_2020,
  ROUND(100 * (depression_2020 - depression_2019) / depression_2019, 4) AS depression_pct_increase
FROM period_2019, period_2020;