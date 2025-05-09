-- Average weekly anxiety and depression levels for the U.S.
-- and percentage increase from the 2019 period to the 2020 period
SELECT
  -- 2019 period averages (2019‑01‑01 to 2019‑12‑31)
  AVG(CASE WHEN dt BETWEEN DATE '2019-01-01' AND DATE '2019-12-31'
           THEN anxiety END)                                       AS avg_anxiety_2019,
  AVG(CASE WHEN dt BETWEEN DATE '2019-01-01' AND DATE '2019-12-31'
           THEN depression END)                                    AS avg_depression_2019,

  -- 2020 period averages (2020‑01‑01 to 2020‑12‑31)
  AVG(CASE WHEN dt BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
           THEN anxiety END)                                       AS avg_anxiety_2020,
  AVG(CASE WHEN dt BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
           THEN depression END)                                    AS avg_depression_2020,

  -- Percentage increase from 2019 period to 2020 period
  (AVG(CASE WHEN dt BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
            THEN anxiety END)
   -
   AVG(CASE WHEN dt BETWEEN DATE '2019-01-01' AND DATE '2019-12-31'
            THEN anxiety END))
   /
   AVG(CASE WHEN dt BETWEEN DATE '2019-01-01' AND DATE '2019-12-31'
            THEN anxiety END) * 100                                AS pct_increase_anxiety,

  (AVG(CASE WHEN dt BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
            THEN depression END)
   -
   AVG(CASE WHEN dt BETWEEN DATE '2019-01-01' AND DATE '2019-12-31'
            THEN depression END))
   /
   AVG(CASE WHEN dt BETWEEN DATE '2019-01-01' AND DATE '2019-12-31'
            THEN depression END) * 100                             AS pct_increase_depression
FROM (
  SELECT
    DATE(`date`)                            AS dt,
    CAST(symptom_anxiety    AS FLOAT64)     AS anxiety,
    CAST(symptom_depression AS FLOAT64)     AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
) AS t;