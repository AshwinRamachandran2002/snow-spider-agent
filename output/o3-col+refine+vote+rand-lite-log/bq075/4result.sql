-- Combined 2021 race & gender distributions:
--   • Google overall hiring
--   • Google overall representation
--   • BLS tech-industry (Internet-publishing / Web-search + Computer-systems-design)

WITH google_hiring AS (
  SELECT
    'Google Hiring (overall, 2021)'                           AS source,
    race_asian                                                AS pct_asian,
    race_black                                                AS pct_black,
    race_hispanic_latinx                                      AS pct_hispanic,
    race_white                                                AS pct_white,
    gender_us_women                                           AS pct_women,
    gender_us_men                                             AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

google_representation AS (
  SELECT
    'Google Representation (overall, 2021)'                   AS source,
    race_asian                                                AS pct_asian,
    race_black                                                AS pct_black,
    race_hispanic_latinx                                      AS pct_hispanic,
    race_white                                                AS pct_white,
    gender_us_women                                           AS pct_women,
    gender_us_men                                             AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

-- Tech industries:  Internet publishing / web-search portals OR
--                   Computer systems design & related services
bls_tech AS (
  WITH tech_rows AS (
    SELECT
      total_employed_in_thousands                    AS emp,
      percent_women,
      percent_white,
      percent_black_or_african_american              AS percent_black,
      percent_hispanic_or_latino                     AS percent_hispanic,
      percent_asian
    FROM `bigquery-public-data.bls.cpsaat18`
    WHERE year = 2021
      AND (
            LOWER(industry_group) LIKE '%computer systems design and related services%'  OR
            LOWER(industry)       LIKE '%computer systems design and related services%'  OR
            LOWER(industry_group) LIKE '%internet publishing%'                           OR
            LOWER(industry)       LIKE '%internet publishing%'                           OR
            LOWER(industry_group) LIKE '%web search portal%'                             OR
            LOWER(industry)       LIKE '%web search portal%'
          )
  )
  SELECT
    'BLS Tech Industries (2021)'                     AS source,
    SUM(emp * percent_asian   ) / SUM(emp)           AS pct_asian,
    SUM(emp * percent_black   ) / SUM(emp)           AS pct_black,
    SUM(emp * percent_hispanic) / SUM(emp)           AS pct_hispanic,
    SUM(emp * percent_white   ) / SUM(emp)           AS pct_white,
    SUM(emp * percent_women   ) / SUM(emp)           AS pct_women,
    1 - SUM(emp * percent_women) / SUM(emp)          AS pct_men
  FROM tech_rows
)

SELECT *
FROM google_hiring

UNION ALL
SELECT *
FROM google_representation

UNION ALL
SELECT *
FROM bls_tech;