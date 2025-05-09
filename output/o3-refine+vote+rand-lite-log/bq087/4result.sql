WITH filtered AS (
  SELECT
    CAST(`date` AS DATE)                     AS week_date,
    SAFE_CAST(symptom_anosmia AS FLOAT64)    AS anosmia
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE country_region          = 'United States'
    AND sub_region_1_code       = 'US-NY'   -- State of New York
    AND sub_region_2 IN ('Bronx County',
                          'Queens County',
                          'Kings County',
                          'New York County',
                          'Richmond County') -- the five NYC counties
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly_avg AS (
  SELECT
    EXTRACT(YEAR FROM week_date) AS yr,
    AVG(anosmia)                 AS avg_anosmia
  FROM filtered
  WHERE anosmia IS NOT NULL
  GROUP BY yr
  HAVING yr IN (2019, 2020)
)
SELECT
  ( (MAX(CASE WHEN yr = 2020 THEN avg_anosmia END)
    - MAX(CASE WHEN yr = 2019 THEN avg_anosmia END))
    / MAX(CASE WHEN yr = 2019 THEN avg_anosmia END) ) * 100
    AS percentage_change
FROM yearly_avg;