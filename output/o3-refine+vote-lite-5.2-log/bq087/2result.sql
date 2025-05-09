WITH filtered AS (
  SELECT
    CAST(`date` AS DATE)                       AS week_start,
    `sub_region_2`,
    SAFE_CAST(`symptom_anosmia` AS FLOAT64)    AS anosmia_value
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE country_region_code = 'US'
    AND sub_region_1        = 'New York'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly_avg AS (
  SELECT
    EXTRACT(YEAR FROM week_start) AS yr,
    AVG(anosmia_value)            AS avg_weekly_anosmia
  FROM filtered
  WHERE anosmia_value IS NOT NULL
  GROUP BY yr
  HAVING yr IN (2019, 2020)
)
SELECT
  AVG(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END) AS avg_2019,
  AVG(CASE WHEN yr = 2020 THEN avg_weekly_anosmia END) AS avg_2020,
  (AVG(CASE WHEN yr = 2020 THEN avg_weekly_anosmia END) -
   AVG(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END))
   / AVG(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END) * 100
   AS percentage_change
FROM yearly_avg;