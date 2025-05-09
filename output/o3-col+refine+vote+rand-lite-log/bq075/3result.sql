/* 2021 race- & gender-distribution comparison
   – Google overall U.S. hiring
   – Google overall U.S. representation
   – BLS tech benchmarks:
       • Internet publishing & web-search portals
       • Computer systems design & related services                              */

WITH google_hiring AS (
  SELECT
    'Google Hiring 2021'     AS source,
    race_asian               AS pct_asian,
    race_black               AS pct_black,
    race_hispanic_latinx     AS pct_hispanic_latino,
    race_white               AS pct_white,
    gender_us_women          AS pct_women,
    gender_us_men            AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
google_repr AS (
  SELECT
    'Google Representation 2021' AS source,
    race_asian                   AS pct_asian,
    race_black                   AS pct_black,
    race_hispanic_latinx         AS pct_hispanic_latino,
    race_white                   AS pct_white,
    gender_us_women              AS pct_women,
    gender_us_men                AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls_tech AS (
  SELECT
    CASE
      WHEN LOWER(
             CONCAT(
               COALESCE(subsector,''),' ',
               COALESCE(industry_group,''),' ',
               COALESCE(industry,'')
             )
           ) LIKE '%internet publishing and broadcasting and web search portals%'
        THEN 'BLS 2021 – Internet publishing & web-search portals'
      WHEN LOWER(
             CONCAT(
               COALESCE(subsector,''),' ',
               COALESCE(industry_group,''),' ',
               COALESCE(industry,'')
             )
           ) LIKE '%computer systems design%'
        THEN 'BLS 2021 – Computer systems design & related services'
    END                                          AS source,
    percent_asian                                AS pct_asian,
    percent_black_or_african_american            AS pct_black,
    percent_hispanic_or_latino                   AS pct_hispanic_latino,
    percent_white                                AS pct_white,
    percent_women                                AS pct_women,
    (1 - percent_women)                          AS pct_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
      LOWER(
        CONCAT(
          COALESCE(subsector,''),' ',
          COALESCE(industry_group,''),' ',
          COALESCE(industry,'')
        )
      ) LIKE '%internet publishing and broadcasting and web search portals%'
      OR LOWER(
        CONCAT(
          COALESCE(subsector,''),' ',
          COALESCE(industry_group,''),' ',
          COALESCE(industry,'')
        )
      ) LIKE '%computer systems design%'
    )
)

SELECT *
FROM (
  SELECT * FROM google_hiring
  UNION ALL
  SELECT * FROM google_repr
  UNION ALL
  SELECT * FROM bls_tech
)
ORDER BY source;