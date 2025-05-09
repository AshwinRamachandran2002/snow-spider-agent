-- Combined 2021 race & gender snapshot:
--   • Google overall workforce – hiring distribution
--   • Google overall workforce – representation distribution
--   • BLS “tech sector” (Internet publishing & broadcasting & web-search portals
--     + Computer systems design & related services) – employment-weighted
--     demographic distribution
WITH
-- 1) Google overall hiring (2021)
google_hiring AS (
  SELECT
    'Google Hiring 2021'                         AS source,
    race_asian                                   AS race_asian,
    race_black                                   AS race_black,
    race_hispanic_latinx                         AS race_hispanic,
    race_white                                   AS race_white,
    gender_us_women                              AS gender_women,
    gender_us_men                                AS gender_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

-- 2) Google overall representation (2021)
google_representation AS (
  SELECT
    'Google Representation 2021'                 AS source,
    race_asian,
    race_black,
    race_hispanic_latinx                         AS race_hispanic,
    race_white,
    gender_us_women                              AS gender_women,
    gender_us_men                                AS gender_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

-- 3) BLS tech‐sector demographics (employment-weighted blend of two target industries)
bls_tech AS (
  SELECT
    'BLS Tech Sectors 2021'                      AS source,
    SUM(total_employed_in_thousands * percent_asian)
      / SUM(total_employed_in_thousands)         AS race_asian,
    SUM(total_employed_in_thousands * percent_black_or_african_american)
      / SUM(total_employed_in_thousands)         AS race_black,
    SUM(total_employed_in_thousands * percent_hispanic_or_latino)
      / SUM(total_employed_in_thousands)         AS race_hispanic,
    SUM(total_employed_in_thousands * percent_white)
      / SUM(total_employed_in_thousands)         AS race_white,
    SUM(total_employed_in_thousands * percent_women)
      / SUM(total_employed_in_thousands)         AS gender_women,
    1 - SUM(total_employed_in_thousands * percent_women)
        / SUM(total_employed_in_thousands)       AS gender_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         LOWER(
           COALESCE(sector,'')        || ' ' ||
           COALESCE(subsector,'')     || ' ' ||
           COALESCE(industry_group,'')|| ' ' ||
           COALESCE(industry,'')
         ) LIKE '%internet publishing and broadcasting and web search portals%'
      OR LOWER(
           COALESCE(sector,'')        || ' ' ||
           COALESCE(subsector,'')     || ' ' ||
           COALESCE(industry_group,'')|| ' ' ||
           COALESCE(industry,'')
         ) LIKE '%computer systems design and related services%'
    )
)

-- Final combined report
SELECT *
FROM google_hiring
UNION ALL
SELECT *
FROM google_representation
UNION ALL
SELECT *
FROM bls_tech;