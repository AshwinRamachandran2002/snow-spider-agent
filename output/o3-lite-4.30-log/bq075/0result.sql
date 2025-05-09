WITH google_hiring AS (
  SELECT
    'Google Hiring'                 AS category,
    race_asian                      AS asian_pct,
    race_black                      AS black_pct,
    race_hispanic_latinx            AS hispanic_latinx_pct,
    race_white                      AS white_pct,
    gender_us_women                 AS women_pct,
    gender_us_men                   AS men_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
google_representation AS (
  SELECT
    'Google Representation'         AS category,
    race_asian                      AS asian_pct,
    race_black                      AS black_pct,
    race_hispanic_latinx            AS hispanic_latinx_pct,
    race_white                      AS white_pct,
    gender_us_women                 AS women_pct,
    gender_us_men                   AS men_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls_tech AS (
  SELECT DISTINCT
    CONCAT('BLS – ', industry)      AS category,
    percent_asian                   AS asian_pct,
    percent_black_or_african_american AS black_pct,
    percent_hispanic_or_latino      AS hispanic_latinx_pct,
    percent_white                   AS white_pct,
    percent_women                   AS women_pct,
    1 - percent_women               AS men_pct
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
      'Computer systems design and related services',
      'Internet publishing and broadcasting and web search portals'
    )
)

SELECT
  category,
  ROUND(asian_pct, 4)           AS asian_pct,
  ROUND(black_pct, 4)           AS black_pct,
  ROUND(hispanic_latinx_pct, 4) AS hispanic_latinx_pct,
  ROUND(white_pct, 4)           AS white_pct,
  ROUND(women_pct, 4)           AS women_pct,
  ROUND(men_pct, 4)             AS men_pct
FROM (
  SELECT * FROM google_hiring
  UNION ALL
  SELECT * FROM google_representation
  UNION ALL
  SELECT * FROM bls_tech
)
ORDER BY category;