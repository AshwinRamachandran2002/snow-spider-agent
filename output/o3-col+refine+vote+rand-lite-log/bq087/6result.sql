-- Overall % change in average weekly Anosmia search frequency (2019 → 2020)
WITH weekly AS (
  SELECT
    CAST(SUBSTR(date,1,4) AS INT64)            AS yr,
    CAST(symptom_anosmia AS FLOAT64)            AS anosmia_score
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_sub_region_2_weekly`
  WHERE sub_region_2 IN ('Bronx County','Queens County','Kings County',
                         'New York County','Richmond County')
    AND date BETWEEN '2019-01-01' AND '2020-12-31'
),
yearly AS (
  SELECT
    yr,
    AVG(anosmia_score) AS avg_anosmia
  FROM weekly
  GROUP BY yr
)
SELECT
  (SELECT avg_anosmia FROM yearly WHERE yr = 2019)                           AS avg_2019,
  (SELECT avg_anosmia FROM yearly WHERE yr = 2020)                           AS avg_2020,
  SAFE_DIVIDE(
      (SELECT avg_anosmia FROM yearly WHERE yr = 2020) -
      (SELECT avg_anosmia FROM yearly WHERE yr = 2019),
      (SELECT avg_anosmia FROM yearly WHERE yr = 2019)
  ) * 100                                                                    AS pct_change_2019_to_2020;