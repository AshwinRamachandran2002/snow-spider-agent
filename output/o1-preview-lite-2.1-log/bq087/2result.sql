SELECT
  ROUND(((avg_2020 - avg_2019) / avg_2019) * 100, 4) AS Collective_Percentage_Change
FROM (
  SELECT
    AVG(CASE WHEN DATE BETWEEN '2019-01-01' AND '2019-12-31' THEN CAST(symptom_anosmia AS FLOAT64) END) AS avg_2019,
    AVG(CASE WHEN DATE BETWEEN '2020-01-01' AND '2020-12-31' THEN CAST(symptom_anosmia AS FLOAT64) END) AS avg_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_daily`
  WHERE
    country_region_code = 'US'
    AND sub_region_1 = 'New York'
    AND sub_region_2 IN ('New York County', 'Kings County', 'Queens County', 'Bronx County', 'Richmond County')
    AND symptom_anosmia IS NOT NULL
)