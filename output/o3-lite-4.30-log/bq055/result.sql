WITH
-- Google 2021 overall hiring percentages
google AS (
  SELECT
    race_white           AS g_white,
    race_black           AS g_black,
    race_asian           AS g_asian,
    race_hispanic_latinx AS g_hispanic
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce = 'overall'
),
-- 2021 BLS tech‑sector workforce averages
bls AS (
  SELECT
    AVG(percent_white)                     AS b_white,
    AVG(percent_black_or_african_american) AS b_black,
    AVG(percent_asian)                     AS b_asian,
    AVG(percent_hispanic_or_latino)        AS b_hispanic
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
          industry IN ('Internet publishing and broadcasting and web search portals',
                       'Software publishers',
                       'Data processing, hosting, and related services')
          OR industry_group = 'Computer systems design and related services'
        )
),
-- Absolute differences between Google hiring and BLS workforce shares
diffs AS (
  SELECT
    ABS(g_white    - b_white)    AS diff_white,
    ABS(g_black    - b_black)    AS diff_black,
    ABS(g_asian    - b_asian)    AS diff_asian,
    ABS(g_hispanic - b_hispanic) AS diff_hispanic
  FROM google CROSS JOIN bls
)
SELECT
  race,
  FORMAT('%.4f', percentage_difference) AS percentage_difference
FROM diffs,
UNNEST([
  STRUCT('White'  AS race, diff_white  AS percentage_difference),
  STRUCT('Asian'  AS race, diff_asian  AS percentage_difference),
  STRUCT('Black'  AS race, diff_black  AS percentage_difference),
  STRUCT('Hispanic/Latinx' AS race, diff_hispanic AS percentage_difference)
])
ORDER BY percentage_difference DESC, race
LIMIT 3;