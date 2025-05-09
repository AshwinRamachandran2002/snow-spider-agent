WITH google AS (
  -- Google 2021 overall U.S. hiring percentages
  SELECT
    race_white           AS g_white,
    race_black           AS g_black,
    race_asian           AS g_asian,
    race_hispanic_latinx AS g_hispanic
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),
bls AS (
  -- 2021 BLS race shares averaged across the four technology-sector categories
  SELECT
    AVG(percent_white)                     AS b_white,
    AVG(percent_black_or_african_american) AS b_black,
    AVG(percent_asian)                     AS b_asian,
    AVG(percent_hispanic_or_latino)        AS b_hispanic
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         LOWER(industry)       LIKE '%internet publishing and broadcasting and web search portals%'  OR
         LOWER(industry)       LIKE '%software publishers%'                                          OR
         LOWER(industry)       LIKE '%data processing, hosting, and related services%'               OR
         LOWER(industry_group) LIKE '%computer systems design and related services%'
        )
),
combined AS (
  -- Combine Google and BLS numbers and calculate absolute differences
  SELECT 'Asian'            AS race, g_asian    AS google_pct, b_asian    AS bls_pct, ABS(g_asian    - b_asian   ) AS pct_diff FROM google CROSS JOIN bls UNION ALL
  SELECT 'White'            AS race, g_white    AS google_pct, b_white    AS bls_pct, ABS(g_white    - b_white   ) AS pct_diff FROM google CROSS JOIN bls UNION ALL
  SELECT 'Black'            AS race, g_black    AS google_pct, b_black    AS bls_pct, ABS(g_black    - b_black   ) AS pct_diff FROM google CROSS JOIN bls UNION ALL
  SELECT 'Hispanic/Latinx'  AS race, g_hispanic AS google_pct, b_hispanic AS bls_pct, ABS(g_hispanic - b_hispanic) AS pct_diff FROM google CROSS JOIN bls
)
-- Return the three races with the largest Google-vs-BLS gaps
SELECT race,
       google_pct,
       bls_pct,
       pct_diff
FROM combined
ORDER BY pct_diff DESC
LIMIT 3;