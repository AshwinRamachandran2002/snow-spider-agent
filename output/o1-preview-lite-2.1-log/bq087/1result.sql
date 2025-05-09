SELECT
  ROUND(((collective_avg_2020 - collective_avg_2019) / collective_avg_2019) * 100, 4) AS Collective_Percentage_Change
FROM (
  SELECT
    AVG(avg_anosmia_2019) AS collective_avg_2019,
    AVG(avg_anosmia_2020) AS collective_avg_2020
  FROM (
    SELECT
      sub_region_2,
      AVG(CASE WHEN EXTRACT(YEAR FROM DATE(date)) = 2019 THEN CAST(symptom_anosmia AS FLOAT64) END) AS avg_anosmia_2019,
      AVG(CASE WHEN EXTRACT(YEAR FROM DATE(date)) = 2020 THEN CAST(symptom_anosmia AS FLOAT64) END) AS avg_anosmia_2020
    FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_daily`
    WHERE
      country_region = 'United States'
      AND sub_region_1 = 'New York'
      AND sub_region_2 IN ('Bronx County', 'Kings County', 'New York County', 'Queens County', 'Richmond County')
      AND DATE(date) BETWEEN DATE '2019-01-01' AND DATE '2020-12-31'
    GROUP BY sub_region_2
  )
)