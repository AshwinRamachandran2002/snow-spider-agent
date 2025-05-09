SELECT
  ROUND(((avg_2020 - avg_2019) / avg_2019) * 100, 4) AS Collective_Percentage_Change
FROM (
  SELECT
    AVG(SAFE_CAST(`symptom_anosmia` AS FLOAT64)) AS avg_2019
  FROM
    `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_daily`
  WHERE
    `sub_region_1` = 'New York'
    AND `sub_region_2` IN ('New York County', 'Kings County', 'Queens County', 'Bronx County', 'Richmond County')
    AND EXTRACT(YEAR FROM DATE(`date`)) = 2019
) AS t2019,
(
  SELECT
    AVG(SAFE_CAST(`symptom_anosmia` AS FLOAT64)) AS avg_2020
  FROM
    `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_daily`
  WHERE
    `sub_region_1` = 'New York'
    AND `sub_region_2` IN ('New York County', 'Kings County', 'Queens County', 'Bronx County', 'Richmond County')
    AND EXTRACT(YEAR FROM DATE(`date`)) = 2020
) AS t2020;