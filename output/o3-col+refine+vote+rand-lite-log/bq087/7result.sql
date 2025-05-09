-- Calculate percentage change in average weekly 'Anosmia' searches
WITH nyc_weeks AS (
  SELECT
    DATE(date)                       AS week_start,
    CAST(symptom_anosmia AS FLOAT64) AS anosmia
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE country_region_code = 'US'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND DATE(date) BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly_avg AS (
  SELECT
    CASE
      WHEN week_start BETWEEN '2019-01-01' AND '2019-12-31' THEN '2019'
      WHEN week_start BETWEEN '2020-01-01' AND '2020-12-31' THEN '2020'
    END                                     AS yr,
    AVG(anosmia) OVER (PARTITION BY CASE
                                         WHEN week_start BETWEEN '2019-01-01' AND '2019-12-31' THEN '2019'
                                         WHEN week_start BETWEEN '2020-01-01' AND '2020-12-31' THEN '2020'
                                       END) AS avg_anosmia
  FROM nyc_weeks
)
SELECT
  MAX(IF(yr = '2019', avg_anosmia, NULL)) AS avg_2019,
  MAX(IF(yr = '2020', avg_anosmia, NULL)) AS avg_2020,
  (MAX(IF(yr = '2020', avg_anosmia, NULL)) -
   MAX(IF(yr = '2019', avg_anosmia, NULL))) /
   MAX(IF(yr = '2019', avg_anosmia, NULL)) * 100  AS pct_change
FROM yearly_avg;