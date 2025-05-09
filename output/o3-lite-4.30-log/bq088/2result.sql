WITH us_weekly AS (
  SELECT
    DATE(date) AS dt,
    SAFE_CAST(symptom_anxiety    AS FLOAT64) AS anxiety,
    SAFE_CAST(symptom_depression AS FLOAT64) AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND date >= '2019-01-01' AND date < '2021-01-01'
),
agg AS (
  SELECT
    AVG(CASE WHEN dt <  '2020-01-01' THEN anxiety    END) AS avg_anxiety_2019,
    AVG(CASE WHEN dt >= '2020-01-01' THEN anxiety    END) AS avg_anxiety_2020,
    AVG(CASE WHEN dt <  '2020-01-01' THEN depression END) AS avg_depression_2019,
    AVG(CASE WHEN dt >= '2020-01-01' THEN depression END) AS avg_depression_2020
  FROM us_weekly
)
SELECT 'anxiety'    AS metric,
       ROUND(avg_anxiety_2019   ,4) AS average_2019,
       ROUND(avg_anxiety_2020   ,4) AS average_2020,
       ROUND(100 * (avg_anxiety_2020   - avg_anxiety_2019)   / avg_anxiety_2019  ,4) AS percentage_increase
FROM agg
UNION ALL
SELECT 'depression' AS metric,
       ROUND(avg_depression_2019,4) AS average_2019,
       ROUND(avg_depression_2020,4) AS average_2020,
       ROUND(100 * (avg_depression_2020 - avg_depression_2019) / avg_depression_2019,4) AS percentage_increase
FROM agg;