-- 2021 racial and gender distribution comparison:
--   1) Google overall workforce – Hiring
--   2) Google overall workforce – Representation
--   3) BLS technology sector (Internet publishing & web‑search portals +
--      Computer systems design & related services)

WITH google_hiring AS (
  SELECT
    'Google Hiring (Overall Workforce)'            AS source,
    race_asian                                    AS pct_asian,
    race_black                                    AS pct_black,
    race_hispanic_latinx                          AS pct_hispanic_latinx,
    race_white                                    AS pct_white,
    gender_us_women                               AS pct_women,
    gender_us_men                                 AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
google_representation AS (
  SELECT
    'Google Representation (Overall Workforce)'   AS source,
    race_asian                                    AS pct_asian,
    race_black                                    AS pct_black,
    race_hispanic_latinx                          AS pct_hispanic_latinx,
    race_white                                    AS pct_white,
    gender_us_women                               AS pct_women,
    gender_us_men                                 AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls_tech AS (
  -- Population‑weighted averages across the two tech industries
  SELECT
    'BLS Tech Sectors (Employment)'               AS source,
    SUM(total_employed_in_thousands * percent_asian)                /
    SUM(total_employed_in_thousands)              AS pct_asian,
    SUM(total_employed_in_thousands * percent_black_or_african_american) /
    SUM(total_employed_in_thousands)              AS pct_black,
    SUM(total_employed_in_thousands * percent_hispanic_or_latino)   /
    SUM(total_employed_in_thousands)              AS pct_hispanic_latinx,
    SUM(total_employed_in_thousands * percent_white)                /
    SUM(total_employed_in_thousands)              AS pct_white,
    SUM(total_employed_in_thousands * percent_women)                /
    SUM(total_employed_in_thousands)              AS pct_women,
    1 - (SUM(total_employed_in_thousands * percent_women) /
         SUM(total_employed_in_thousands))        AS pct_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Computer systems design and related services'
    )
)

SELECT * FROM google_hiring
UNION ALL
SELECT * FROM google_representation
UNION ALL
SELECT * FROM bls_tech;