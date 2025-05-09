/* 2021 comparison of race & gender distributions
   – Google overall hiring
   – Google overall representation
   – BLS tech sectors: “Internet publishing …”  +  “Computer systems design …”   */

WITH google_hiring AS (
  SELECT
    'google_hiring'  AS dataset,
    'Google – Hiring (Overall workforce)' AS group_name,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women            AS gender_women,
    gender_us_men              AS gender_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
google_representation AS (
  SELECT
    'google_representation'    AS dataset,
    'Google – Representation (Overall workforce)' AS group_name,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women            AS gender_women,
    gender_us_men              AS gender_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls_tech AS (
  SELECT
    'bls_tech'                 AS dataset,
    'BLS – Tech sectors (Internet publishing & Computer systems design)' AS group_name,
    -- employment-weighted averages across the two tech industries
    SUM(total_employed_in_thousands * percent_asian)                    / SUM(total_employed_in_thousands) AS race_asian,
    SUM(total_employed_in_thousands * percent_black_or_african_american)/ SUM(total_employed_in_thousands) AS race_black,
    SUM(total_employed_in_thousands * percent_hispanic_or_latino)       / SUM(total_employed_in_thousands) AS race_hispanic_latinx,
    SUM(total_employed_in_thousands * percent_white)                    / SUM(total_employed_in_thousands) AS race_white,
    SUM(total_employed_in_thousands * percent_women)                    / SUM(total_employed_in_thousands) AS gender_women,
    1 - ( SUM(total_employed_in_thousands * percent_women)
          / SUM(total_employed_in_thousands) )                          AS gender_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND LOWER(industry) IN (
          'internet publishing and broadcasting and web search portals',
          'computer systems design and related services'
        )
)
-- combined report
SELECT * FROM google_hiring
UNION ALL
SELECT * FROM google_representation
UNION ALL
SELECT * FROM bls_tech;