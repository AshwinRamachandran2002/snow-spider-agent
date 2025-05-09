WITH us_weekly AS (
  SELECT
    DATE(`date`)                                       AS dt,
    CAST(symptom_anxiety    AS FLOAT64)                AS anxiety,
    CAST(symptom_depression AS FLOAT64)                AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
),
filtered AS (
  SELECT
    CASE
      WHEN dt >= '2019-01-01' AND dt < '2020-01-01' THEN '2019'
      WHEN dt >= '2020-01-01' AND dt < '2021-01-01' THEN '2020'
    END                                               AS period,
    anxiety,
    depression
  FROM us_weekly
  WHERE dt >= '2019-01-01' AND dt < '2021-01-01'
),
avg_per_period AS (
  SELECT
    period,
    AVG(anxiety)    AS avg_anxiety,
    AVG(depression) AS avg_depression
  FROM filtered
  GROUP BY period
)
SELECT
  symptom,
  avg_2019,
  avg_2020,
  (avg_2020 - avg_2019) / avg_2019 * 100 AS pct_increase
FROM (
  SELECT
    'anxiety'                             AS symptom,
    (SELECT avg_anxiety    FROM avg_per_period WHERE period = '2019') AS avg_2019,
    (SELECT avg_anxiety    FROM avg_per_period WHERE period = '2020') AS avg_2020
  UNION ALL
  SELECT
    'depression',
    (SELECT avg_depression FROM avg_per_period WHERE period = '2019'),
    (SELECT avg_depression FROM avg_per_period WHERE period = '2020')
)