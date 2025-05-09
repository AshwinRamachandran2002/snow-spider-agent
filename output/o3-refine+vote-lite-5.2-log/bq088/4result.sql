-- Average weekly anxiety and depression symptom levels for the U.S.
-- in 2019 (2019‑01‑01 to 2020‑01‑01) and 2020 (2020‑01‑01 to 2021‑01‑01)
-- plus the percentage increase from 2019 to 2020.

WITH filtered AS (
  SELECT
    DATE(`date`)                               AS week_start,
    CAST(symptom_anxiety    AS FLOAT64) AS anxiety,
    CAST(symptom_depression AS FLOAT64) AS depression,
    CASE
      WHEN DATE(`date`) BETWEEN '2019-01-01' AND '2019-12-31' THEN 'period_2019'
      WHEN DATE(`date`) BETWEEN '2020-01-01' AND '2020-12-31' THEN 'period_2020'
    END AS period
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
        AND DATE(`date`) BETWEEN '2019-01-01' AND '2020-12-31'
),
period_avg AS (
  SELECT
    period,
    AVG(anxiety)    AS avg_anxiety,
    AVG(depression) AS avg_depression
  FROM filtered
  GROUP BY period
)
SELECT
  p19.avg_anxiety    AS avg_anxiety_2019,
  p20.avg_anxiety    AS avg_anxiety_2020,
  SAFE_DIVIDE(p20.avg_anxiety - p19.avg_anxiety, p19.avg_anxiety) * 100
                     AS anxiety_pct_increase,
  p19.avg_depression AS avg_depression_2019,
  p20.avg_depression AS avg_depression_2020,
  SAFE_DIVIDE(p20.avg_depression - p19.avg_depression, p19.avg_depression) * 100
                     AS depression_pct_increase
FROM period_avg p19
JOIN period_avg p20
  ON p19.period = 'period_2019'
 AND p20.period = 'period_2020';