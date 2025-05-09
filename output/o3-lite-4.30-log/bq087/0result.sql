WITH filtered AS (
  SELECT
    DATE(`date`) AS week_start,
    SAFE_CAST(symptom_anosmia AS FLOAT64) AS anosmia_value
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE country_region_code = 'US'
    AND sub_region_1 = 'New York'
    AND sub_region_2 IN ('Bronx County','Queens County','Kings County',
                         'New York County','Richmond County')
    AND DATE(`date`) BETWEEN '2019-01-01' AND '2020-12-31'
),
year_avg AS (
  SELECT
    EXTRACT(YEAR FROM week_start) AS yr,
    AVG(anosmia_value) AS avg_year_anosmia
  FROM filtered
  GROUP BY yr
)
SELECT
  ROUND(
    SAFE_DIVIDE(
      MAX(IF(yr = 2020, avg_year_anosmia, NULL)) -
      MAX(IF(yr = 2019, avg_year_anosmia, NULL)),
      MAX(IF(yr = 2019, avg_year_anosmia, NULL))
    ) * 100,
    4
  ) AS percentage_change
FROM year_avg;