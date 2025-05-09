SELECT
  'anxiety' AS Symptom,
  ROUND(AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_anxiety` AS FLOAT64) END), 4) AS `2019_Average_Level`,
  ROUND(AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_anxiety` AS FLOAT64) END), 4) AS `2020_Average_Level`,
  ROUND(
    (
      AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_anxiety` AS FLOAT64) END) -
      AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_anxiety` AS FLOAT64) END)
    ) /
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_anxiety` AS FLOAT64) END) * 100,
    4
  ) AS Percentage_Increase
FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
WHERE `country_region_code` = 'US' AND EXTRACT(YEAR FROM DATE(`date`)) IN (2019, 2020)

UNION ALL

SELECT
  'depression' AS Symptom,
  ROUND(AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_depression` AS FLOAT64) END), 4) AS `2019_Average_Level`,
  ROUND(AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_depression` AS FLOAT64) END), 4) AS `2020_Average_Level`,
  ROUND(
    (
      AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2020 THEN CAST(`symptom_depression` AS FLOAT64) END) -
      AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_depression` AS FLOAT64) END)
    ) /
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(`date`)) = 2019 THEN CAST(`symptom_depression` AS FLOAT64) END) * 100,
    4
  ) AS Percentage_Increase
FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
WHERE `country_region_code` = 'US' AND EXTRACT(YEAR FROM DATE(`date`)) IN (2019, 2020);