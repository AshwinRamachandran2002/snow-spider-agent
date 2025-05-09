WITH google_hiring AS (
  SELECT
    'Google Overall Hiring (2021)'                          AS source,
    race_asian                                              AS pct_asian,
    race_black                                              AS pct_black,
    race_hispanic_latinx                                    AS pct_hispanic_latinx,
    race_white                                              AS pct_white,
    gender_us_women                                         AS pct_women,
    gender_us_men                                           AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

google_representation AS (
  SELECT
    'Google Overall Representation (2021)'                  AS source,
    race_asian                                              AS pct_asian,
    race_black                                              AS pct_black,
    race_hispanic_latinx                                    AS pct_hispanic_latinx,
    race_white                                              AS pct_white,
    gender_us_women                                         AS pct_women,
    gender_us_men                                           AS pct_men
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

bls_tech_sector AS (
  /* 2021 tech‑sector workforce (Internet publishing & Computer systems design) */
  SELECT
    'BLS Tech Sector (2021)'                                AS source,
    SUM(percent_asian                   * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)                    AS pct_asian,
    SUM(percent_black_or_african_american * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)                    AS pct_black,
    SUM(percent_hispanic_or_latino        * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)                    AS pct_hispanic_latinx,
    SUM(percent_white                    * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)                    AS pct_white,
    SUM(percent_women                    * total_employed_in_thousands)
      / SUM(total_employed_in_thousands)                    AS pct_women,
    1 - (SUM(percent_women              * total_employed_in_thousands)
      /   SUM(total_employed_in_thousands))                 AS pct_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
      'Internet publishing and broadcasting and web search portals',
      'Computer systems design and related services'
    )
)

SELECT *
FROM (
  SELECT * FROM google_hiring
  UNION ALL
  SELECT * FROM google_representation
  UNION ALL
  SELECT * FROM bls_tech_sector
)
ORDER BY source;