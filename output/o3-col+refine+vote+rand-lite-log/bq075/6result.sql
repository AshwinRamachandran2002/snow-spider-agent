/* 2021 – Racial & gender mix:
      • Google overall hiring
      • Google overall representation
      • BLS tech-sector employment (Internet publishing & web-search portals  +  Computer systems design & related services)
*/
WITH bls_tech AS (
  SELECT
    'BLS_tech_sectors_2021'                                  AS bucket,
    SUM(`total_employed_in_thousands`)                       AS total_emp_000s,
    ROUND( SUM(`total_employed_in_thousands` * `percent_women`)
           / SUM(`total_employed_in_thousands`), 4)          AS percent_women,
    ROUND( 1 - SUM(`total_employed_in_thousands` * `percent_women`)
               / SUM(`total_employed_in_thousands`), 4)      AS percent_men,
    ROUND( SUM(`total_employed_in_thousands` * `percent_white`)
           / SUM(`total_employed_in_thousands`), 4)          AS percent_white,
    ROUND( SUM(`total_employed_in_thousands` * `percent_black_or_african_american`)
           / SUM(`total_employed_in_thousands`), 4)          AS percent_black,
    ROUND( SUM(`total_employed_in_thousands` * `percent_asian`)
           / SUM(`total_employed_in_thousands`), 4)          AS percent_asian,
    ROUND( SUM(`total_employed_in_thousands` * `percent_hispanic_or_latino`)
           / SUM(`total_employed_in_thousands`), 4)          AS percent_hispanic_latinx
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE `year` = 2021
    AND LOWER(`industry`) IN (
      'internet publishing and broadcasting and web search portals',
      'computer systems design and related services'
    )
)

SELECT *
FROM (
  /* ── Google OVERALL hiring ── */
  SELECT
    'Google_hiring_2021'                           AS bucket,
    NULL                                           AS total_emp_000s,
    ROUND(`gender_us_women`,4)                     AS percent_women,
    ROUND(`gender_us_men`,4)                       AS percent_men,
    ROUND(`race_white`,4)                          AS percent_white,
    ROUND(`race_black`,4)                          AS percent_black,
    ROUND(`race_asian`,4)                          AS percent_asian,
    ROUND(`race_hispanic_latinx`,4)                AS percent_hispanic_latinx
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE `workforce` = 'overall'
    AND `report_year` = 2021

  UNION ALL

  /* ── Google OVERALL representation ── */
  SELECT
    'Google_representation_2021'                   AS bucket,
    NULL                                           AS total_emp_000s,
    ROUND(`gender_us_women`,4),
    ROUND(`gender_us_men`,4),
    ROUND(`race_white`,4),
    ROUND(`race_black`,4),
    ROUND(`race_asian`,4),
    ROUND(`race_hispanic_latinx`,4)
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_representation`
  WHERE `workforce` = 'overall'
    AND `report_year` = 2021

  UNION ALL

  /* ── BLS tech-sector aggregate ── */
  SELECT
    bucket,
    total_emp_000s,
    percent_women,
    percent_men,
    percent_white,
    percent_black,
    percent_asian,
    percent_hispanic_latinx
  FROM bls_tech
)
ORDER BY bucket;