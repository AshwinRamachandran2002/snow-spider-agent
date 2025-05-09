WITH agg AS (
  SELECT
    AVG(CASE WHEN DATE(date) BETWEEN '2019-01-01' AND '2019-12-31'
             THEN CAST(symptom_anxiety AS FLOAT64) END)    AS anxiety_2019,
    AVG(CASE WHEN DATE(date) BETWEEN '2020-01-01' AND '2020-12-31'
             THEN CAST(symptom_anxiety AS FLOAT64) END)    AS anxiety_2020,
    AVG(CASE WHEN DATE(date) BETWEEN '2019-01-01' AND '2019-12-31'
             THEN CAST(symptom_depression AS FLOAT64) END) AS depression_2019,
    AVG(CASE WHEN DATE(date) BETWEEN '2020-01-01' AND '2020-12-31'
             THEN CAST(symptom_depression AS FLOAT64) END) AS depression_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
)

SELECT 'anxiety'   AS metric,
       ROUND(anxiety_2019   ,4) AS average_2019,
       ROUND(anxiety_2020   ,4) AS average_2020,
       ROUND(100 * (anxiety_2020 - anxiety_2019) / anxiety_2019,4) AS percentage_increase
FROM agg

UNION ALL

SELECT 'depression',
       ROUND(depression_2019,4),
       ROUND(depression_2020,4),
       ROUND(100 * (depression_2020 - depression_2019) / depression_2019,4)
FROM agg

ORDER BY metric;