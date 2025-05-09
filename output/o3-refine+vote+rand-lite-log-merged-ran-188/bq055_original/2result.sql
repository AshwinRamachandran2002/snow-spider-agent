WITH google AS (
  /* Google's 2021 overall hiring percentages */
  SELECT 'asian'            AS race, race_asian          AS pct FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'black',            race_black                  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'hispanic_latinx',  race_hispanic_latinx        FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
  UNION ALL
  SELECT 'white',            race_white                  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021 AND workforce = 'overall'
),
bls_raw AS (
  /* 2021 BLS employment‑share rows for the four tech‑industry categories */
  SELECT
    percent_asian,
    percent_black_or_african_american,
    percent_hispanic_or_latino,
    percent_white
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         industry IN (
           'Internet publishing and broadcasting and web search portals',
           'Software publishers',
           'Data processing, hosting, and related services'
         )
         OR industry_group = 'Computer systems design and related services'
    )
),
bls AS (
  /* Average BLS percentages across those four categories */
  SELECT 'asian'           AS race, AVG(percent_asian)                       AS pct FROM bls_raw UNION ALL
  SELECT 'black',              AVG(percent_black_or_african_american)            FROM bls_raw UNION ALL
  SELECT 'hispanic_latinx',    AVG(percent_hispanic_or_latino)                   FROM bls_raw UNION ALL
  SELECT 'white',              AVG(percent_white)                                FROM bls_raw
),
diffs AS (
  /* Absolute percentage‑point difference between Google & BLS */
  SELECT
    g.race,
    ABS(g.pct - b.pct) AS pct_difference
  FROM google g
  JOIN bls   b USING (race)
)
SELECT
  race,
  ROUND(pct_difference, 4) AS pct_difference
FROM diffs
ORDER BY pct_difference DESC
LIMIT 3;