WITH nyc_county_weeks AS (
  SELECT
    DATE(`date`)                             AS week_start,
    CAST(symptom_anosmia AS FLOAT64)         AS anosmia_value
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE country_region_code = 'US'
    AND sub_region_1       = 'New York'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND DATE(`date`) BETWEEN '2019-01-01' AND '2020-12-31'
    AND symptom_anosmia IS NOT NULL
), year_average AS (
  SELECT
    EXTRACT(YEAR FROM week_start) AS yr,
    AVG(anosmia_value)            AS avg_weekly_anosmia
  FROM nyc_county_weeks
  GROUP BY yr
  HAVING yr IN (2019, 2020)
)
SELECT
  MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END) AS avg_2019,
  MAX(CASE WHEN yr = 2020 THEN avg_weekly_anosmia END) AS avg_2020,
  ( (MAX(CASE WHEN yr = 2020 THEN avg_weekly_anosmia END) -
      MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END))
    / MAX(CASE WHEN yr = 2019 THEN avg_weekly_anosmia END) ) * 100
    AS percentage_change
FROM year_average;