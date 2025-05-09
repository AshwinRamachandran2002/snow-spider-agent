-- Overall % change in average weekly “Anosmia” search frequency (2020 vs 2019)
WITH nyc_weekly AS (
  SELECT
    SUBSTR(`date`,1,4)                       AS yr,              -- '2019' / '2020'
    SAFE_CAST(`symptom_anosmia` AS FLOAT64)  AS anosmia_val
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE `country_region_code` = 'US'
    AND `sub_region_1`       = 'New York'
    AND `sub_region_2` IN ('Bronx County','Queens County',
                           'Kings County','New York County',
                           'Richmond County')
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly_avg AS (
  SELECT
    yr,
    AVG(anosmia_val) AS avg_anosmia
  FROM nyc_weekly
  GROUP BY yr
)
SELECT
  (MAX(CASE WHEN yr = '2020' THEN avg_anosmia END) -
   MAX(CASE WHEN yr = '2019' THEN avg_anosmia END))
  / MAX(CASE WHEN yr = '2019' THEN avg_anosmia END) * 100
    AS percent_change_2020_vs_2019
FROM yearly_avg;