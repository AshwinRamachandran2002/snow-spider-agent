-- 2021 Racial & Gender comparison:
--   • Google overall workforce – HIRING
--   • Google overall workforce – REPRESENTATION
--   • BLS tech‑sector workforce (Internet publishing & web search portals + Computer systems design & related services)

WITH bls_tech AS (     -- aggregate two tech‑oriented industries, employment–weighted
  SELECT
    SUM(total_employed_in_thousands)                                                 AS total_emp,
    SUM(total_employed_in_thousands * percent_asian)              / SUM(total_employed_in_thousands) AS race_asian,
    SUM(total_employed_in_thousands * percent_black_or_african_american)
                                                                  / SUM(total_employed_in_thousands) AS race_black,
    SUM(total_employed_in_thousands * percent_hispanic_or_latino) / SUM(total_employed_in_thousands) AS race_hispanic_latinx,
    SUM(total_employed_in_thousands * percent_white)              / SUM(total_employed_in_thousands) AS race_white,
    SUM(total_employed_in_thousands * percent_women)              / SUM(total_employed_in_thousands) AS gender_us_women
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN ('Internet publishing and broadcasting and web search portals',
                     'Computer systems design and related services')
),

bls_final AS (
  SELECT
    'BLS Tech Industries 2021'                                              AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    1 - gender_us_women                                                     AS gender_us_men
  FROM bls_tech
)

SELECT * FROM (
  -- Google hiring
  SELECT
    'Google Hiring 2021'                         AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall' AND report_year = 2021

  UNION ALL
  -- Google representation
  SELECT
    'Google Representation 2021'                 AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2021

  UNION ALL
  -- BLS tech industries
  SELECT * FROM bls_final
);