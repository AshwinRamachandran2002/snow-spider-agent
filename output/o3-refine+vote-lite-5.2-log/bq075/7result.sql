/* 2021 racial and gender distribution comparison:
     – Google overall hiring
     – Google overall workforce representation
     – BLS CPSAAT18 technology‑sector rows
       (Internet publishing, broadcasting & web search portals;
        Computer systems design & related services)                                   */

WITH
-- Google 2021 overall hiring
google_hiring_2021 AS (
  SELECT
    'Google Hiring Overall 2021' AS source,
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

-- Google 2021 overall in‑house representation
google_rep_2021 AS (
  SELECT
    'Google Workforce Overall 2021' AS source,
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

-- BLS CPSAAT18 2021 rows for two “tech sector” industries
bls_tech_2021 AS (
  SELECT
    CASE
      WHEN industry = 'Computer systems design and related services' THEN
        'BLS Computer Systems Design 2021'
      WHEN industry = 'Internet publishing, broadcasting, and web search portals' THEN
        'BLS Internet Publishing & Web Search 2021'
    END                                                        AS source,
    percent_asian                                              AS race_asian,
    percent_black_or_african_american                          AS race_black,
    percent_hispanic_or_latino                                 AS race_hispanic_latinx,
    percent_white                                              AS race_white,
    percent_women                                              AS gender_us_women,
    (1 - percent_women)                                        AS gender_us_men
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND industry IN (
      'Computer systems design and related services',
      'Internet publishing, broadcasting, and web search portals'
    )
)

-- Combine all four rows
SELECT
  source,
  ROUND(race_asian, 4)           AS race_asian,
  ROUND(race_black, 4)           AS race_black,
  ROUND(race_hispanic_latinx,4)  AS race_hispanic_latinx,
  ROUND(race_white, 4)           AS race_white,
  ROUND(gender_us_women, 4)      AS gender_us_women,
  ROUND(gender_us_men, 4)        AS gender_us_men
FROM (
  SELECT * FROM google_hiring_2021
  UNION ALL
  SELECT * FROM google_rep_2021
  UNION ALL
  SELECT * FROM bls_tech_2021
)
ORDER BY source;