-- Overall % change in average weekly ‘Anosmia’ search frequency
-- for the five New York City counties (Bronx, Queens, Kings, New York, Richmond)
-- comparing calendar‑year 2019 with 2020
WITH base AS (
  SELECT
    CAST(`date` AS DATE)                           AS week_start,
    EXTRACT(YEAR FROM CAST(`date` AS DATE))        AS yr,
    CAST(symptom_anosmia AS FLOAT64)               AS anosmia
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE sub_region_1 = 'New York'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'
),
-- average across the five counties for every epidemiological week
week_avg AS (
  SELECT
    week_start,
    yr,
    AVG(anosmia) AS week_avg_anosmia
  FROM base
  GROUP BY week_start, yr
),
-- average of those weekly values within each calendar year
year_avg AS (
  SELECT
    yr,
    AVG(week_avg_anosmia) AS avg_anosmia
  FROM week_avg
  GROUP BY yr
)
SELECT
  MAX(IF(yr = 2019, avg_anosmia, NULL)) AS avg_weekly_anosmia_2019,
  MAX(IF(yr = 2020, avg_anosmia, NULL)) AS avg_weekly_anosmia_2020,
  SAFE_DIVIDE(
      MAX(IF(yr = 2020, avg_anosmia, NULL)) -
      MAX(IF(yr = 2019, avg_anosmia, NULL)),
      MAX(IF(yr = 2019, avg_anosmia, NULL))
  ) * 100                             AS pct_change_2019_to_2020
FROM year_avg;