-- Calculate average weekly anxiety & depression levels for the U.S. in 2019 vs 2020
WITH us_weekly AS (
  SELECT
    DATE(`date`)                           AS date,
    SAFE_CAST(`symptom_anxiety`    AS FLOAT64) AS anxiety,
    SAFE_CAST(`symptom_depression` AS FLOAT64) AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE `country_region_code` = 'US'
    AND `date` BETWEEN '2019-01-01' AND '2020-12-31'      -- span both full years
),
long_form AS (
  -- Put the two symptoms into one column
  SELECT 'anxiety'    AS symptom, anxiety    AS value,
         CASE WHEN date >= '2019-01-01' AND date < '2020-01-01' THEN '2019'
              WHEN date >= '2020-01-01' AND date < '2021-01-01' THEN '2020' END AS period
  FROM us_weekly
  UNION ALL
  SELECT 'depression', depression,
         CASE WHEN date >= '2019-01-01' AND date < '2020-01-01' THEN '2019'
              WHEN date >= '2020-01-01' AND date < '2021-01-01' THEN '2020' END
  FROM us_weekly
)
SELECT
  symptom,
  AVG(CASE WHEN period = '2019' THEN value END) AS avg_2019,
  AVG(CASE WHEN period = '2020' THEN value END) AS avg_2020,
  (AVG(CASE WHEN period = '2020' THEN value END)
   - AVG(CASE WHEN period = '2019' THEN value END))
   * 100 / AVG(CASE WHEN period = '2019' THEN value END) AS pct_increase
FROM long_form
GROUP BY symptom;