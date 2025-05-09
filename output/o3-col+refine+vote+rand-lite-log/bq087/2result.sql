-- Calculate the percentage change in the average weekly “Anosmia” search
-- interest for the five New York City counties between 2019 and 2020
SELECT
  ROUND( (avg_2020 - avg_2019) / avg_2019 * 100 , 2) AS percent_change
FROM (
  SELECT
    AVG(CASE
          WHEN DATE(`date`) BETWEEN '2019-01-01' AND '2019-12-31'
          THEN CAST(`symptom_anosmia` AS FLOAT64)
        END) AS avg_2019,
    AVG(CASE
          WHEN DATE(`date`) BETWEEN '2020-01-01' AND '2020-12-31'
          THEN CAST(`symptom_anosmia` AS FLOAT64)
        END) AS avg_2020
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE `sub_region_1` = 'New York'
    AND `sub_region_2` IN (
          'Bronx County',
          'Queens County',
          'Kings County',
          'New York County',
          'Richmond County'
        )
);