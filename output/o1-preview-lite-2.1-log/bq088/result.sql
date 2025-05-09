SELECT
  'anxiety' AS Symptom,
  AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_anxiety` AS FLOAT64) END) AS `2019_Average_Level`,
  AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_anxiety` AS FLOAT64) END) AS `2020_Average_Level`,
  ((AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_anxiety` AS FLOAT64) END) -
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_anxiety` AS FLOAT64) END)
   ) / 
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_anxiety` AS FLOAT64) END)
  ) * 100 AS `Percentage_Increase`
FROM
  `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
WHERE
  `country_region` = 'United States'
  AND EXTRACT(YEAR FROM DATE(`date`)) IN (2019, 2020)

UNION ALL

SELECT
  'depression' AS Symptom,
  AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_depression` AS FLOAT64) END) AS `2019_Average_Level`,
  AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_depression` AS FLOAT64) END) AS `2020_Average_Level`,
  ((AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_depression` AS FLOAT64) END) -
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_depression` AS FLOAT64) END)
   ) / 
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_depression` AS FLOAT64) END)
  ) * 100 AS `Percentage_Increase`
FROM
  `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
WHERE
  `country_region` = 'United States'
  AND EXTRACT(YEAR FROM DATE(`date`)) IN (2019, 2020);