WITH nyc_anosmia AS (
  SELECT
    SAFE_CAST(`symptom_anosmia` AS FLOAT64) AS anosmia,
    EXTRACT(YEAR FROM DATE(`date`))           AS yr
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE `country_region_code` = 'US'
    AND `sub_region_1`        = 'New York'
    AND `sub_region_2` IN ('Bronx County',
                           'Queens County',
                           'Kings County',
                           'New York County',
                           'Richmond County')
    AND DATE(`date`) BETWEEN '2019-01-01' AND '2020-12-31'
)

SELECT
  ROUND( (avg_2020 - avg_2019) / avg_2019 * 100 , 2) AS pct_change_anosmia
FROM (
  SELECT
    AVG(CASE WHEN yr = 2019 THEN anosmia END) AS avg_2019,
    AVG(CASE WHEN yr = 2020 THEN anosmia END) AS avg_2020
  FROM nyc_anosmia
);