WITH google_hiring AS (
  SELECT
    'Google – Hiring 2021' AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
google_representation AS (
  SELECT
    'Google – Representation 2021' AS source,
    race_asian,
    race_black,
    race_hispanic_latinx,
    race_white,
    gender_us_women,
    gender_us_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls_tech AS (
  SELECT
    'BLS – Tech Sectors 2021' AS source,
    AVG(percent_asian)                     AS race_asian,
    AVG(percent_black_or_african_american) AS race_black,
    AVG(percent_hispanic_or_latino)        AS race_hispanic_latinx,
    AVG(percent_white)                     AS race_white,
    AVG(percent_women)                     AS gender_us_women,
    1 - AVG(percent_women)                 AS gender_us_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Computer systems design and related services'
    )
)
SELECT
  source,
  race_asian,
  race_black,
  race_hispanic_latinx,
  race_white,
  gender_us_women,
  gender_us_men
FROM google_hiring

UNION ALL

SELECT
  source,
  race_asian,
  race_black,
  race_hispanic_latinx,
  race_white,
  gender_us_women,
  gender_us_men
FROM google_representation

UNION ALL

SELECT
  source,
  race_asian,
  race_black,
  race_hispanic_latinx,
  race_white,
  gender_us_women,
  gender_us_men
FROM bls_tech;