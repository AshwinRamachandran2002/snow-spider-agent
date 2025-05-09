-- Calculate average weekly anxiety & depression symptom levels for the U.S.
-- during 2019-calendar year (2019-01-01 ≤ date < 2020-01-01)
-- and 2020-calendar year (2020-01-01 ≤ date < 2021-01-01),
-- then compute the percentage change from 2019 to 2020.

WITH base AS (
  SELECT
    CASE
      WHEN `date` >= '2019-01-01' AND `date` < '2020-01-01' THEN '2019'
      WHEN `date` >= '2020-01-01' AND `date` < '2021-01-01' THEN '2020'
    END AS period,
    CAST(`symptom_anxiety`    AS FLOAT64) AS anxiety,
    CAST(`symptom_depression` AS FLOAT64) AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE `country_region_code` = 'US'
    AND `date` >= '2019-01-01'
    AND `date`  < '2021-01-01'
),
agg AS (
  SELECT
    period,
    AVG(anxiety)    AS avg_anxiety,
    AVG(depression) AS avg_depression
  FROM base
  GROUP BY period
)
SELECT
  y19.avg_anxiety        AS avg_anxiety_2019,
  y20.avg_anxiety        AS avg_anxiety_2020,
  ROUND((y20.avg_anxiety - y19.avg_anxiety) / y19.avg_anxiety * 100, 2)
                        AS anxiety_pct_increase,
  y19.avg_depression     AS avg_depression_2019,
  y20.avg_depression     AS avg_depression_2020,
  ROUND((y20.avg_depression - y19.avg_depression) / y19.avg_depression * 100, 2)
                        AS depression_pct_increase
FROM (SELECT * FROM agg WHERE period = '2019') y19
CROSS JOIN (SELECT * FROM agg WHERE period = '2020') y20;