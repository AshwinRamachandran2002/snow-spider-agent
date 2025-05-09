WITH
-- 1. Google 2021 HIRING (overall workforce, U.S.)
google_hiring AS (
  SELECT
    'Google – Hiring (overall workforce, 2021)'                         AS segment,
    race_asian                                                         AS pct_asian,
    race_black                                                         AS pct_black,
    race_hispanic_latinx                                               AS pct_hispanic_latinx,
    race_white                                                         AS pct_white,
    gender_us_women                                                   AS pct_women,
    gender_us_men                                                     AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

-- 2. Google 2021 REPRESENTATION (overall workforce, U.S.)
google_representation AS (
  SELECT
    'Google – Representation (overall workforce, 2021)'                AS segment,
    race_asian                                                         AS pct_asian,
    race_black                                                         AS pct_black,
    race_hispanic_latinx                                               AS pct_hispanic_latinx,
    race_white                                                         AS pct_white,
    gender_us_women                                                   AS pct_women,
    gender_us_men                                                     AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

-- 3. BLS 2021 technology‐sector workforce (Internet publishing …  &  Computer systems design …)
bls_tech AS (
  SELECT
    CONCAT('BLS – ', industry, ' (2021)')                              AS segment,
    percent_asian                                                      AS pct_asian,
    percent_black_or_african_american                                  AS pct_black,
    percent_hispanic_or_latino                                         AS pct_hispanic_latinx,
    percent_white                                                      AS pct_white,
    percent_women                                                      AS pct_women,
    1.0 - percent_women                                               AS pct_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
          'Internet publishing and broadcasting and web search portals',
          'Computer systems design and related services'
        )
)

-- Combine the three data sources
SELECT *
FROM (
  SELECT * FROM google_hiring
  UNION ALL
  SELECT * FROM google_representation
  UNION ALL
  SELECT * FROM bls_tech
)
ORDER BY segment;