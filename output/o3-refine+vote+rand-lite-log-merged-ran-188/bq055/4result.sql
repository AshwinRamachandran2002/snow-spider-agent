-- Top-3 races with the largest 2021 percentage-gaps between Google overall hiring
-- and 2021 BLS tech-sector workforce averages
WITH google AS (
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
  SELECT
    AVG(percent_white)                     AS b_white,
    AVG(percent_black_or_african_american) AS b_black,
    AVG(percent_asian)                     AS b_asian,
    AVG(percent_hispanic_or_latino)        AS b_hispanic
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         LOWER(industry) = 'internet publishing and broadcasting and web search portals'
      OR LOWER(industry) = 'software publishers'
      OR LOWER(industry) = 'data processing, hosting, and related services'
      OR LOWER(industry_group) = 'computer systems design and related services'
    )
),
gaps AS (
  SELECT
    ABS(g_white - b_white)       AS diff_white,
    ABS(g_black - b_black)       AS diff_black,
    ABS(g_asian - b_asian)       AS diff_asian,
    ABS(g_hispanic - b_hispanic) AS diff_hispanic
  FROM google, bls
),
unpivot AS (
  SELECT 'White'    AS race, diff_white    AS diff FROM gaps UNION ALL
  SELECT 'Black'    AS race, diff_black    AS diff FROM gaps UNION ALL
  SELECT 'Asian'    AS race, diff_asian    AS diff FROM gaps UNION ALL
  SELECT 'Hispanic' AS race, diff_hispanic AS diff FROM gaps
)
SELECT race, diff
FROM unpivot
ORDER BY diff DESC
LIMIT 3;