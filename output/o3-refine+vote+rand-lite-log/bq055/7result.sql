WITH bls_tech AS (
  /* Average 2021 BLS race percentages for the four specified tech industries   */
  SELECT
    AVG(percent_white)                    AS white_pct,
    AVG(percent_black_or_african_american) AS black_pct,
    AVG(percent_asian)                    AS asian_pct,
    AVG(percent_hispanic_or_latino)       AS hispanic_pct
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND LOWER(industry) IN (
      'internet publishing and broadcasting and web search portals',
      'software publishers',
      'data processing, hosting, and related services',
      'computer systems design and related services'
    )
),
google_overall_2021 AS (
  /* Google 2021 overall U.S. hiring percentages                              */
  SELECT
    race_white          AS white_pct,
    race_black          AS black_pct,
    race_asian          AS asian_pct,
    race_hispanic_latinx AS hispanic_pct
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
race_diffs AS (
  /* Absolute percentage-point differences between Google and BLS averages    */
  SELECT 'White'       AS race, ABS(g.white_pct   - b.white_pct)    AS diff FROM google_overall_2021 g CROSS JOIN bls_tech b UNION ALL
  SELECT 'Black'       AS race, ABS(g.black_pct   - b.black_pct)    AS diff FROM google_overall_2021 g CROSS JOIN bls_tech b UNION ALL
  SELECT 'Asian'       AS race, ABS(g.asian_pct   - b.asian_pct)    AS diff FROM google_overall_2021 g CROSS JOIN bls_tech b UNION ALL
  SELECT 'Hispanic/Latinx' AS race, ABS(g.hispanic_pct - b.hispanic_pct) AS diff FROM google_overall_2021 g CROSS JOIN bls_tech b
)
SELECT race,
       ROUND(diff, 4) AS percentage_point_difference
FROM race_diffs
ORDER BY diff DESC
LIMIT 3;