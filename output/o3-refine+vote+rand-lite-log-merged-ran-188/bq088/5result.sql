WITH us_weekly AS (
  SELECT
    CASE
      WHEN DATE(`date`) >= DATE '2019-01-01' AND DATE(`date`) < DATE '2020-01-01' THEN '2019'
      WHEN DATE(`date`) >= DATE '2020-01-01' AND DATE(`date`) < DATE '2021-01-01' THEN '2020'
      ELSE NULL
    END                                             AS period,
    SAFE_CAST(symptom_anxiety    AS FLOAT64)        AS anxiety,
    SAFE_CAST(symptom_depression AS FLOAT64)        AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND DATE(`date`) >= DATE '2019-01-01'
    AND DATE(`date`) <  DATE '2021-01-01'
)
SELECT
  ROUND(AVG(CASE WHEN period = '2019' THEN anxiety END), 4) AS avg_anxiety_2019,
  ROUND(AVG(CASE WHEN period = '2020' THEN anxiety END), 4) AS avg_anxiety_2020,
  ROUND(
        (AVG(CASE WHEN period = '2020' THEN anxiety END)
       -  AVG(CASE WHEN period = '2019' THEN anxiety END))
       / AVG(CASE WHEN period = '2019' THEN anxiety END) * 100
  , 4) AS anxiety_pct_increase,
  
  ROUND(AVG(CASE WHEN period = '2019' THEN depression END), 4) AS avg_depression_2019,
  ROUND(AVG(CASE WHEN period = '2020' THEN depression END), 4) AS avg_depression_2020,
  ROUND(
        (AVG(CASE WHEN period = '2020' THEN depression END)
       -  AVG(CASE WHEN period = '2019' THEN depression END))
       / AVG(CASE WHEN period = '2019' THEN depression END) * 100
  , 4) AS depression_pct_increase
FROM us_weekly
WHERE period IS NOT NULL;