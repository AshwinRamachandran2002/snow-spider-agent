SELECT
  ROUND(
    SAFE_DIVIDE(avg_2020 - avg_2019, avg_2019) * 100,
    4
  ) AS percentage_change
FROM (
  SELECT
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(date)) = 2019
             THEN CAST(symptom_anosmia AS FLOAT64) END) AS avg_2019,
    AVG(CASE WHEN EXTRACT(YEAR FROM DATE(date)) = 2020
             THEN CAST(symptom_anosmia AS FLOAT64) END) AS avg_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE sub_region_2 IN ('Bronx County', 'Queens County', 'Kings County',
                         'New York County', 'Richmond County')
    AND DATE(date) BETWEEN '2019-01-01' AND '2020-12-31'
);