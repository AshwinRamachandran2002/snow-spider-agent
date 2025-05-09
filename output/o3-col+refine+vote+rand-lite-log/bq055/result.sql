-- Top 3 races/ethnicities with the largest percentage-point gaps between
-- Google’s 2021 overall U.S. hiring and 2021 BLS tech-sector averages
WITH google AS (
  SELECT
    race_white           AS g_white,
    race_black           AS g_black,
    race_asian           AS g_asian,
    race_hispanic_latinx AS g_hispanic
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce   = 'overall'
),
bls AS (
  -- Average 2021 CPS percentages for four tech industries
  SELECT
    AVG(percent_white)                     AS b_white,
    AVG(percent_black_or_african_american) AS b_black,
    AVG(percent_asian)                     AS b_asian,
    AVG(percent_hispanic_or_latino)        AS b_hispanic
  FROM (
    SELECT
      percent_white,
      percent_black_or_african_american,
      percent_asian,
      percent_hispanic_or_latino,
      LOWER(
        CONCAT(
          COALESCE(sector,''),            ' ',
          COALESCE(subsector,''),         ' ',
          COALESCE(industry_group,''),    ' ',
          COALESCE(industry,'')
        )
      ) AS descr
    FROM `bigquery-public-data.bls.cpsaat18`
    WHERE year = 2021
  )
  WHERE descr LIKE '%internet publishing%'
     OR descr LIKE '%software publishers%'
     OR descr LIKE '%data processing%'
     OR descr LIKE '%computer systems design%'
),
diffs AS (
  -- Absolute percentage-point differences
  SELECT 'White'           AS race, ABS(g_white    - b_white   ) AS diff FROM google, bls UNION ALL
  SELECT 'Asian'           AS race, ABS(g_asian    - b_asian   )        FROM google, bls UNION ALL
  SELECT 'Black'           AS race, ABS(g_black    - b_black   )        FROM google, bls UNION ALL
  SELECT 'Hispanic/Latinx' AS race, ABS(g_hispanic - b_hispanic)        FROM google, bls
)
SELECT race, diff
FROM diffs
ORDER BY diff DESC
LIMIT 3;