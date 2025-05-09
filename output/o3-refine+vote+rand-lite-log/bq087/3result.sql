WITH county_data AS (
  SELECT
    EXTRACT(YEAR FROM DATE(`date`)) AS yr,
    SAFE_CAST(symptom_anosmia AS FLOAT64)          AS anosmia_val
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE country_region_code = 'US'
    AND sub_region_1        = 'New York'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND DATE(`date`) BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly_avg AS (
  SELECT
    yr,
    AVG(anosmia_val) AS avg_anosmia
  FROM county_data
  WHERE anosmia_val IS NOT NULL
  GROUP BY yr
)
SELECT
  ROUND(
        (
          (SELECT avg_anosmia FROM yearly_avg WHERE yr = 2020) -
          (SELECT avg_anosmia FROM yearly_avg WHERE yr = 2019)
        )
        /
        (SELECT avg_anosmia FROM yearly_avg WHERE yr = 2019)
        * 100
       , 4
  ) AS percentage_change