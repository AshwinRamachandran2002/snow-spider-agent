SELECT
  AVG(CASE WHEN `date` BETWEEN '2019-01-01' AND '2019-12-31'
           THEN SAFE_CAST(`symptom_anosmia` AS FLOAT64) END) AS avg_2019,
  AVG(CASE WHEN `date` BETWEEN '2020-01-01' AND '2020-12-31'
           THEN SAFE_CAST(`symptom_anosmia` AS FLOAT64) END) AS avg_2020,
  100 * (
        AVG(CASE WHEN `date` BETWEEN '2020-01-01' AND '2020-12-31'
                 THEN SAFE_CAST(`symptom_anosmia` AS FLOAT64) END) -
        AVG(CASE WHEN `date` BETWEEN '2019-01-01' AND '2019-12-31'
                 THEN SAFE_CAST(`symptom_anosmia` AS FLOAT64) END)
      )
      / AVG(CASE WHEN `date` BETWEEN '2019-01-01' AND '2019-12-31'
                 THEN SAFE_CAST(`symptom_anosmia` AS FLOAT64) END) AS pct_change
FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
WHERE `country_region` = 'United States'
  AND `sub_region_1`   = 'New York'
  AND `sub_region_2` IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County');