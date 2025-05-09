/*--------------------------------------------------------------------
2021 Race & Gender comparison
   1) Google overall – Hiring (U.S.)
   2) Google overall – Workforce representation (U.S.)
   3) BLS – Tech sector (Internet publishing & broadcasting and web‑search
      portals  +  Computer systems design & related services)
--------------------------------------------------------------------*/
WITH
-- 1. Google overall hiring
google_hiring AS (
  SELECT
    'Google – Hiring (overall)'          AS category,
    race_asian                           AS pct_race_asian,
    race_black                           AS pct_race_black,
    race_hispanic_latinx                 AS pct_race_hispanic_latinx,
    race_white                           AS pct_race_white,
    gender_us_women                      AS pct_us_women,
    gender_us_men                        AS pct_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

-- 2. Google overall representation
google_rep AS (
  SELECT
    'Google – Representation (overall)'  AS category,
    race_asian                           AS pct_race_asian,
    race_black                           AS pct_race_black,
    race_hispanic_latinx                 AS pct_race_hispanic_latinx,
    race_white                           AS pct_race_white,
    gender_us_women                      AS pct_us_women,
    gender_us_men                        AS pct_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

-- 3. BLS CPS – technology industries, employment‑weighted averages
bls_tech AS (
  SELECT
    'BLS – Tech sector (Internet publishing & computer systems design)' AS category,
    SUM(total_employed_in_thousands * percent_asian              ) / SUM(total_employed_in_thousands)  AS pct_race_asian,
    SUM(total_employed_in_thousands * percent_black_or_african_american) / SUM(total_employed_in_thousands)  AS pct_race_black,
    SUM(total_employed_in_thousands * percent_hispanic_or_latino  ) / SUM(total_employed_in_thousands)  AS pct_race_hispanic_latinx,
    SUM(total_employed_in_thousands * percent_white              ) / SUM(total_employed_in_thousands)  AS pct_race_white,
    SUM(total_employed_in_thousands * percent_women              ) / SUM(total_employed_in_thousands)  AS pct_us_women,
    1 - (SUM(total_employed_in_thousands * percent_women) / SUM(total_employed_in_thousands))          AS pct_us_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Computer systems design and related services'
    )
)

-- Final union of the three sources
SELECT * FROM google_hiring
UNION ALL
SELECT * FROM google_rep
UNION ALL
SELECT * FROM bls_tech;