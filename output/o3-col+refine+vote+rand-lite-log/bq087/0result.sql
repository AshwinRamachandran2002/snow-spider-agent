WITH base AS (
  SELECT
    SUBSTR(date, 1, 4) AS yr,
    SAFE_CAST(symptom_anosmia AS FLOAT64) AS val
  FROM
    `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE
    country_region_code = 'US'
    AND sub_region_1 = 'New York'
    AND sub_region_2 IN ('Bronx County',
                         'Queens County',
                         'Kings County',
                         'New York County',
                         'Richmond County')
    AND date BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly AS (
  SELECT
    yr,
    AVG(val) AS avg_val
  FROM base
  GROUP BY yr
)
SELECT
  ROUND(
    (MAX(IF(yr = '2020', avg_val, NULL)) -
     MAX(IF(yr = '2019', avg_val, NULL)))
    / MAX(IF(yr = '2019', avg_val, NULL)) * 100,
    2
  ) AS percentage_change_2019_to_2020
FROM yearly;