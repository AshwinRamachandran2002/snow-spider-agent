-- Average weekly anxiety & depression for the U.S. in 2019 vs 2020
-- and the percentage change between the two periods
SELECT
  -- 2019 averages (2019-01-01 ≤ date < 2020-01-01)
  AVG(CASE
        WHEN date >= '2019-01-01' AND date < '2020-01-01'
        THEN CAST(symptom_anxiety AS FLOAT64)
      END) AS avg_anxiety_2019,
  AVG(CASE
        WHEN date >= '2019-01-01' AND date < '2020-01-01'
        THEN CAST(symptom_depression AS FLOAT64)
      END) AS avg_depression_2019,

  -- 2020 averages (2020-01-01 ≤ date < 2021-01-01)
  AVG(CASE
        WHEN date >= '2020-01-01' AND date < '2021-01-01'
        THEN CAST(symptom_anxiety AS FLOAT64)
      END) AS avg_anxiety_2020,
  AVG(CASE
        WHEN date >= '2020-01-01' AND date < '2021-01-01'
        THEN CAST(symptom_depression AS FLOAT64)
      END) AS avg_depression_2020,

  -- Percentage increase from 2019 → 2020
  ( (AVG(CASE WHEN date >= '2020-01-01' AND date < '2021-01-01'
              THEN CAST(symptom_anxiety AS FLOAT64) END)
     -
     AVG(CASE WHEN date >= '2019-01-01' AND date < '2020-01-01'
              THEN CAST(symptom_anxiety AS FLOAT64) END))
    /
     AVG(CASE WHEN date >= '2019-01-01' AND date < '2020-01-01'
              THEN CAST(symptom_anxiety AS FLOAT64) END) ) * 100
    AS pct_increase_anxiety,

  ( (AVG(CASE WHEN date >= '2020-01-01' AND date < '2021-01-01'
              THEN CAST(symptom_depression AS FLOAT64) END)
     -
     AVG(CASE WHEN date >= '2019-01-01' AND date < '2020-01-01'
              THEN CAST(symptom_depression AS FLOAT64) END))
    /
     AVG(CASE WHEN date >= '2019-01-01' AND date < '2020-01-01'
              THEN CAST(symptom_depression AS FLOAT64) END) ) * 100
    AS pct_increase_depression
FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
WHERE country_region_code = 'US';