-- Top 3 races with the largest 2021 hiring-share gaps between Google (overall workforce)
-- and the 2021 BLS tech-industry average
WITH google AS (
  SELECT
    race_white            AS google_white ,
    race_black            AS google_black ,
    race_asian            AS google_asian ,
    race_hispanic_latinx  AS google_hispanic
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce   = 'overall'
),

bls AS (
  SELECT
    AVG(percent_white)                     AS bls_white ,
    AVG(percent_black_or_african_american) AS bls_black ,
    AVG(percent_asian)                     AS bls_asian ,
    AVG(percent_hispanic_or_latino)        AS bls_hispanic
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND LOWER(industry_group) IN (
          'internet publishing and broadcasting and web search portals',
          'software publishers',
          'data processing, hosting, and related services',
          'computer systems design and related services'
        )
)

SELECT
  race,
  diff
FROM (
  SELECT 'White'              AS race, google_white  - bls_white     AS diff FROM google, bls UNION ALL
  SELECT 'Black'              AS race, google_black  - bls_black     AS diff FROM google, bls UNION ALL
  SELECT 'Asian'              AS race, google_asian  - bls_asian     AS diff FROM google, bls UNION ALL
  SELECT 'Hispanic or Latino' AS race, google_hispanic- bls_hispanic AS diff FROM google, bls
)
ORDER BY ABS(diff) DESC
LIMIT 3;