WITH us_weekly AS (
  SELECT
    CAST(`date` AS DATE) AS dt,
    SAFE_CAST(`symptom_anxiety`   AS FLOAT64) AS anxiety,
    SAFE_CAST(`symptom_depression` AS FLOAT64) AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
    AND sub_region_1 IS NULL      -- keep country‑level rows only
),

agg AS (
  -- Anxiety
  SELECT
    'anxiety' AS symptom,
    AVG(CASE WHEN dt >= '2019-01-01' AND dt < '2020-01-01' THEN anxiety END) AS avg_2019,
    AVG(CASE WHEN dt >= '2020-01-01' AND dt < '2021-01-01' THEN anxiety END) AS avg_2020
  FROM us_weekly
  
  UNION ALL
  
  -- Depression
  SELECT
    'depression' AS symptom,
    AVG(CASE WHEN dt >= '2019-01-01' AND dt < '2020-01-01' THEN depression END),
    AVG(CASE WHEN dt >= '2020-01-01' AND dt < '2021-01-01' THEN depression END)
  FROM us_weekly
)

SELECT
  symptom,
  avg_2019,
  avg_2020,
  (avg_2020 - avg_2019) / avg_2019 * 100 AS pct_increase
FROM agg;