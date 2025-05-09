WITH us_weekly AS (
  SELECT
    DATE(`date`) AS dt,
    CAST(symptom_anxiety   AS FLOAT64) AS anxiety,
    CAST(symptom_depression AS FLOAT64) AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
),
period_avgs AS (
  SELECT
    CASE
      WHEN dt BETWEEN '2019-01-01' AND '2019-12-31' THEN '2019_period'
      WHEN dt BETWEEN '2020-01-01' AND '2020-12-31' THEN '2020_period'
    END                                                             AS period,
    AVG(anxiety)    AS avg_anxiety,
    AVG(depression) AS avg_depression
  FROM us_weekly
  WHERE dt BETWEEN '2019-01-01' AND '2020-12-31'
  GROUP BY period
),
pivot AS (
  SELECT
    MAX(CASE WHEN period = '2019_period' THEN avg_anxiety    END) AS avg_anxiety_2019,
    MAX(CASE WHEN period = '2020_period' THEN avg_anxiety    END) AS avg_anxiety_2020,
    MAX(CASE WHEN period = '2019_period' THEN avg_depression END) AS avg_depression_2019,
    MAX(CASE WHEN period = '2020_period' THEN avg_depression END) AS avg_depression_2020
  FROM period_avgs
)
SELECT
  avg_anxiety_2019,
  avg_anxiety_2020,
  SAFE_DIVIDE(avg_anxiety_2020 - avg_anxiety_2019, avg_anxiety_2019) * 100 AS anxiety_pct_increase,
  avg_depression_2019,
  avg_depression_2020,
  SAFE_DIVIDE(avg_depression_2020 - avg_depression_2019, avg_depression_2019) * 100 AS depression_pct_increase
FROM pivot;