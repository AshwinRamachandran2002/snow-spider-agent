WITH nyc AS (
  SELECT
    DATE(`date`) AS dt,
    CAST(`symptom_anosmia` AS FLOAT64) AS val
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE `country_region_code` = 'US'
    AND `sub_region_1_code` = 'US-NY'
    AND `sub_region_2` IN ('Bronx County', 'Queens County', 'Kings County',
                           'New York County', 'Richmond County')
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'
),
weekly AS (
  SELECT
    dt,
    AVG(val) AS weekly_avg
  FROM nyc
  GROUP BY dt
),
year_avgs AS (
  SELECT
    EXTRACT(YEAR FROM dt) AS yr,
    AVG(weekly_avg) AS avg_weekly_anosmia
  FROM weekly
  GROUP BY yr
)
SELECT
  ROUND(
    (MAX(CASE WHEN yr = 2020 THEN avg_weekly_anosmia END) -
     MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END))
    / MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END) * 100,
    4
  ) AS percentage_change
FROM year_avgs;