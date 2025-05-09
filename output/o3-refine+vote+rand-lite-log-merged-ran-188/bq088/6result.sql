/*  Average weekly anxiety and depression search levels in the U.S.
    – 2019 period : 2019‑01‑01  up to but not including 2020‑01‑01
    – 2020 period : 2020‑01‑01  up to but not including 2021‑01‑01
    The percentage increase is computed from the 2019 average to the 2020 average.
*/
SELECT
  -- anxiety
  AVG(CASE WHEN dt BETWEEN '2019-01-01' AND '2019-12-31' THEN anxiety END)              AS avg_anxiety_2019,
  AVG(CASE WHEN dt BETWEEN '2020-01-01' AND '2020-12-31' THEN anxiety END)              AS avg_anxiety_2020,
  (AVG(CASE WHEN dt BETWEEN '2020-01-01' AND '2020-12-31' THEN anxiety END) -
   AVG(CASE WHEN dt BETWEEN '2019-01-01' AND '2019-12-31' THEN anxiety END))
   /
   AVG(CASE WHEN dt BETWEEN '2019-01-01' AND '2019-12-31' THEN anxiety END) * 100       AS anxiety_pct_increase,

  -- depression
  AVG(CASE WHEN dt BETWEEN '2019-01-01' AND '2019-12-31' THEN depression END)           AS avg_depression_2019,
  AVG(CASE WHEN dt BETWEEN '2020-01-01' AND '2020-12-31' THEN depression END)           AS avg_depression_2020,
  (AVG(CASE WHEN dt BETWEEN '2020-01-01' AND '2020-12-31' THEN depression END) -
   AVG(CASE WHEN dt BETWEEN '2019-01-01' AND '2019-12-31' THEN depression END))
   /
   AVG(CASE WHEN dt BETWEEN '2019-01-01' AND '2019-12-31' THEN depression END) * 100    AS depression_pct_increase
FROM (
  SELECT
    DATE(`date`)                           AS dt,
    SAFE_CAST(symptom_anxiety    AS FLOAT64) AS anxiety,
    SAFE_CAST(symptom_depression AS FLOAT64) AS depression
  FROM `bigquery-public-data.covid19_symptom_search.symptom_search_country_weekly`
  WHERE country_region_code = 'US'
  -- keep only weeks needed for both periods
  AND DATE(`date`) BETWEEN '2019-01-01' AND '2020-12-31'
);