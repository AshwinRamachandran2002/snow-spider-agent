WITH nyc_weekly AS (
  SELECT
    DATE(`date`)                           AS week_start,
    CAST(symptom_anosmia AS FLOAT64)       AS anosmia_value,
    EXTRACT(YEAR FROM DATE(`date`))        AS yr
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
),
yearly_avg AS (
  SELECT
    yr                                                       AS year,
    AVG(anosmia_value)                                       AS avg_weekly_anosmia
  FROM nyc_weekly
  GROUP BY yr
)
SELECT
  ROUND( (avg_2020 - avg_2019) / avg_2019 * 100 , 4) AS percentage_change
FROM (
  SELECT
    MAX(CASE WHEN year = 2019 THEN avg_weekly_anosmia END) AS avg_2019,
    MAX(CASE WHEN year = 2020 THEN avg_weekly_anosmia END) AS avg_2020
  FROM yearly_avg
);