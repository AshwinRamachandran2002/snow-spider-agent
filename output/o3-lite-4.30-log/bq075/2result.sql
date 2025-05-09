WITH google_hiring AS (
  SELECT
    'Google Hiring 2021' AS category,
    ROUND(race_asian, 4)           AS asian_pct,
    ROUND(race_black, 4)           AS black_pct,
    ROUND(race_hispanic_latinx, 4) AS hispanic_latinx_pct,
    ROUND(race_white, 4)           AS white_pct,
    ROUND(gender_us_women, 4)      AS women_pct,
    ROUND(gender_us_men, 4)        AS men_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
google_representation AS (
  SELECT
    'Google Representation 2021' AS category,
    ROUND(race_asian, 4)           AS asian_pct,
    ROUND(race_black, 4)           AS black_pct,
    ROUND(race_hispanic_latinx, 4) AS hispanic_latinx_pct,
    ROUND(race_white, 4)           AS white_pct,
    ROUND(gender_us_women, 4)      AS women_pct,
    ROUND(gender_us_men, 4)        AS men_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls_internet AS (
  SELECT
    'BLS Internet publishing (NAICS 51913) 2021' AS category,
    ROUND(percent_asian, 4)                     AS asian_pct,
    ROUND(percent_black_or_african_american, 4) AS black_pct,
    ROUND(percent_hispanic_or_latino, 4)        AS hispanic_latinx_pct,
    ROUND(percent_white, 4)                     AS white_pct,
    ROUND(percent_women, 4)                     AS women_pct,
    ROUND(1 - percent_women, 4)                 AS men_pct
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND subsector = 'Internet publishing and broadcasting and web search portals'
),
bls_comp_design AS (
  SELECT
    'BLS Computer systems design (NAICS 5415) 2021' AS category,
    ROUND(percent_asian, 4)                     AS asian_pct,
    ROUND(percent_black_or_african_american, 4) AS black_pct,
    ROUND(percent_hispanic_or_latino, 4)        AS hispanic_latinx_pct,
    ROUND(percent_white, 4)                     AS white_pct,
    ROUND(percent_women, 4)                     AS women_pct,
    ROUND(1 - percent_women, 4)                 AS men_pct
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry = 'Computer systems design and related services'
)

SELECT *
FROM google_hiring
UNION ALL
SELECT * FROM google_representation
UNION ALL
SELECT * FROM bls_internet
UNION ALL
SELECT * FROM bls_comp_design
ORDER BY category;