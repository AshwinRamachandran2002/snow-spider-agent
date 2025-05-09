WITH
  avg_2019 AS (
    SELECT AVG(CAST(symptom_anosmia AS FLOAT64)) AS avg_anosmia_2019
    FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
    WHERE sub_region_2 IN ('Bronx County', 'Queens County', 'Kings County', 'New York County', 'Richmond County')
      AND date BETWEEN '2019-01-01' AND '2019-12-31'
      AND symptom_anosmia IS NOT NULL
  ),
  avg_2020 AS (
    SELECT AVG(CAST(symptom_anosmia AS FLOAT64)) AS avg_anosmia_2020
    FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
    WHERE sub_region_2 IN ('Bronx County', 'Queens County', 'Kings County', 'New York County', 'Richmond County')
      AND date BETWEEN '2020-01-01' AND '2020-12-31'
      AND symptom_anosmia IS NOT NULL
  )
SELECT
  ROUND(((avg_2020.avg_anosmia_2020 - avg_2019.avg_anosmia_2019) / avg_2019.avg_anosmia_2019) * 100, 4) AS Percentage_change
FROM
  avg_2019, avg_2020;