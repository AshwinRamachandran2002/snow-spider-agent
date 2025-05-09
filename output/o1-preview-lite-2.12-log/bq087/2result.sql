SELECT
  ROUND(((data_2020.avg_2020 - data_2019.avg_2019) / data_2019.avg_2019) * 100, 4) AS Percentage_change
FROM
  (
    SELECT
      AVG(CAST(symptom_anosmia AS FLOAT64)) AS avg_2019
    FROM
      `bigquery-public-data`.`covid19_symptom_search`.`symptom_search_sub_region_2_weekly`
    WHERE
      `country_region_code` = 'US'
      AND `sub_region_1` = 'New York'
      AND `sub_region_2` IN ('Bronx County', 'Queens County', 'Kings County', 'New York County', 'Richmond County')
      AND `date` BETWEEN '2019-01-01' AND '2019-12-31'
      AND `symptom_anosmia` IS NOT NULL
      AND `symptom_anosmia` != ''
  ) AS data_2019,
  (
    SELECT
      AVG(CAST(symptom_anosmia AS FLOAT64)) AS avg_2020
    FROM
      `bigquery-public-data`.`covid19_symptom_search`.`symptom_search_sub_region_2_weekly`
    WHERE
      `country_region_code` = 'US'
      AND `sub_region_1` = 'New York'
      AND `sub_region_2` IN ('Bronx County', 'Queens County', 'Kings County', 'New York County', 'Richmond County')
      AND `date` BETWEEN '2020-01-01' AND '2020-12-31'
      AND `symptom_anosmia` IS NOT NULL
      AND `symptom_anosmia` != ''
  ) AS data_2020;