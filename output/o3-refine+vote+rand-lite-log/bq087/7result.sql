WITH nyc_weekly AS (
  SELECT
    DATE(`date`)                         AS week_start,
    CAST(symptom_anosmia AS FLOAT64)     AS anosmia_value
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE country_region_code = 'US'
    AND sub_region_1 = 'New York'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND symptom_anosmia IS NOT NULL
),
period_avgs AS (
  SELECT
    AVG(CASE WHEN week_start BETWEEN '2019-01-01' AND '2019-12-31'
             THEN anosmia_value END) AS avg_2019,
    AVG(CASE WHEN week_start BETWEEN '2020-01-01' AND '2020-12-31'
             THEN anosmia_value END) AS avg_2020
  FROM nyc_weekly
)
SELECT
  avg_2019,
  avg_2020,
  ROUND( (avg_2020 - avg_2019) * 100.0 / avg_2019 , 4) AS percentage_change
FROM period_avgs;