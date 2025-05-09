-- 2021 racial & gender distribution comparison:
--   • Google overall workforce hiring
--   • Google overall workforce representation
--   • BLS “Computer systems design & related services”
--   • BLS “Internet publishing & broadcasting and Web search portals”

WITH google_hiring AS (
  SELECT
    'Google Overall Hiring 2021'          AS category,
    race_asian                            AS pct_asian,
    race_black                            AS pct_black,
    race_hispanic_latinx                  AS pct_hispanic_latinx,
    race_white                            AS pct_white,
    gender_us_women                       AS pct_women,
    gender_us_men                         AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall' AND report_year = 2021
),

google_representation AS (
  SELECT
    'Google Overall Representation 2021'  AS category,
    race_asian                            AS pct_asian,
    race_black                            AS pct_black,
    race_hispanic_latinx                  AS pct_hispanic_latinx,
    race_white                            AS pct_white,
    gender_us_women                       AS pct_women,
    gender_us_men                         AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall' AND report_year = 2021
),

bls_computer_systems AS (
  SELECT
    'BLS Computer Systems Design 2021'     AS category,
    percent_asian                          AS pct_asian,
    percent_black_or_african_american      AS pct_black,
    percent_hispanic_or_latino             AS pct_hispanic_latinx,
    percent_white                          AS pct_white,
    percent_women                          AS pct_women,
    1 - percent_women                      AS pct_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
          LOWER(COALESCE(industry,       ''))       LIKE '%computer systems design%' OR
          LOWER(COALESCE(industry_group, ''))       LIKE '%computer systems design%' OR
          LOWER(COALESCE(subsector,      ''))       LIKE '%computer systems design%' OR
          LOWER(COALESCE(sector,         ''))       LIKE '%computer systems design%'
        )
),

bls_internet_publishing AS (
  SELECT
    'BLS Internet Publishing/Web Search 2021' AS category,
    percent_asian                              AS pct_asian,
    percent_black_or_african_american          AS pct_black,
    percent_hispanic_or_latino                 AS pct_hispanic_latinx,
    percent_white                              AS pct_white,
    percent_women                              AS pct_women,
    1 - percent_women                          AS pct_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
          LOWER(COALESCE(industry,       ''))       LIKE '%internet publishing%'          OR
          LOWER(COALESCE(industry,       ''))       LIKE '%web search%'                  OR
          LOWER(COALESCE(industry_group, ''))       LIKE '%internet publishing%'          OR
          LOWER(COALESCE(industry_group, ''))       LIKE '%web search%'                  OR
          LOWER(COALESCE(subsector,      ''))       LIKE '%internet publishing%'          OR
          LOWER(COALESCE(subsector,      ''))       LIKE '%web search%'                  OR
          LOWER(COALESCE(sector,         ''))       LIKE '%internet publishing%'          OR
          LOWER(COALESCE(sector,         ''))       LIKE '%web search%'
        )
)

SELECT *
FROM google_hiring
UNION ALL
SELECT *
FROM google_representation
UNION ALL
SELECT *
FROM bls_computer_systems
UNION ALL
SELECT *
FROM bls_internet_publishing;