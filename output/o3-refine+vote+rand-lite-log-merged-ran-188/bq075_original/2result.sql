WITH google_hiring AS (
  SELECT
    'Google Hiring'                                              AS category,
    ROUND(race_asian, 4)                                         AS pct_asian,
    ROUND(race_black, 4)                                         AS pct_black,
    ROUND(race_hispanic_latinx, 4)                               AS pct_hispanic_latinx,
    ROUND(race_white, 4)                                         AS pct_white,
    ROUND(gender_us_women, 4)                                    AS pct_women,
    ROUND(gender_us_men, 4)                                      AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

google_representation AS (
  SELECT
    'Google Representation'                                      AS category,
    ROUND(race_asian, 4)                                         AS pct_asian,
    ROUND(race_black, 4)                                         AS pct_black,
    ROUND(race_hispanic_latinx, 4)                               AS pct_hispanic_latinx,
    ROUND(race_white, 4)                                         AS pct_white,
    ROUND(gender_us_women, 4)                                    AS pct_women,
    ROUND(gender_us_men, 4)                                      AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

bls_tech AS (
  SELECT
    'BLS Tech Sectors'                                           AS category,
    ROUND(SUM(total_employed_in_thousands * percent_asian)
          / SUM(total_employed_in_thousands), 4)                 AS pct_asian,
    ROUND(SUM(total_employed_in_thousands * percent_black_or_african_american)
          / SUM(total_employed_in_thousands), 4)                 AS pct_black,
    ROUND(SUM(total_employed_in_thousands * percent_hispanic_or_latino)
          / SUM(total_employed_in_thousands), 4)                 AS pct_hispanic_latinx,
    ROUND(SUM(total_employed_in_thousands * percent_white)
          / SUM(total_employed_in_thousands), 4)                 AS pct_white,
    ROUND(SUM(total_employed_in_thousands * percent_women)
          / SUM(total_employed_in_thousands), 4)                 AS pct_women,
    ROUND(1 - (SUM(total_employed_in_thousands * percent_women)
          / SUM(total_employed_in_thousands)), 4)                AS pct_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN ('Internet publishing and broadcasting and web search portals',
                     'Computer systems design and related services')
)

SELECT * FROM google_hiring
UNION ALL
SELECT * FROM google_representation
UNION ALL
SELECT * FROM bls_tech
ORDER BY category;