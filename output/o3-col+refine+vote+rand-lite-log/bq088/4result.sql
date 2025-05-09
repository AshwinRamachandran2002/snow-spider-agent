-- Average weekly anxiety & depression levels for the U.S. in 2019 vs. 2020
-- plus percentage change from 2019 to 2020
SELECT
  anxiety_2019,
  anxiety_2020,
  SAFE_DIVIDE(anxiety_2020 - anxiety_2019, anxiety_2019) * 100  AS anxiety_pct_increase,
  depression_2019,
  depression_2020,
  SAFE_DIVIDE(depression_2020 - depression_2019, depression_2019) * 100 AS depression_pct_increase
FROM (
  SELECT
    -- 2019 averages (2019-01-01 to 2019-12-31)
    AVG(CASE
          WHEN DATE(date) >= '2019-01-01' AND DATE(date) < '2020-01-01'
          THEN CAST(symptom_anxiety    AS FLOAT64)
        END) AS anxiety_2019,
    AVG(CASE
          WHEN DATE(date) >= '2019-01-01' AND DATE(date) < '2020-01-01'
          THEN CAST(symptom_depression AS FLOAT64)
        END) AS depression_2019,

    -- 2020 averages (2020-01-01 to 2020-12-31)
    AVG(CASE
          WHEN DATE(date) >= '2020-01-01' AND DATE(date) < '2021-01-01'
          THEN CAST(symptom_anxiety    AS FLOAT64)
        END) AS anxiety_2020,
    AVG(CASE
          WHEN DATE(date) >= '2020-01-01' AND DATE(date) < '2021-01-01'
          THEN CAST(symptom_depression AS FLOAT64)
        END) AS depression_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
);