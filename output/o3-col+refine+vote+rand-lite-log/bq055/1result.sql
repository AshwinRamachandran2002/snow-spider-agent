WITH google AS (
  SELECT
    1 AS id,
    race_asian           AS g_asian,
    race_black           AS g_black,
    race_hispanic_latinx AS g_hispanic,
    race_white           AS g_white
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce = 'overall'
),
bls AS (
  SELECT
    1 AS id,
    AVG(percent_asian)                     AS b_asian,
    AVG(percent_black_or_african_american) AS b_black,
    AVG(percent_hispanic_or_latino)        AS b_hispanic,
    AVG(percent_white)                     AS b_white
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND REGEXP_CONTAINS(
          LOWER(
            CONCAT(
              COALESCE(subsector, ''), ' ',
              COALESCE(industry_group, ''), ' ',
              COALESCE(industry, '')
            )
          ),
          '(internet publishing and broadcasting and web search portals|software publishers|data processing, hosting, and related services|computer systems design and related services)'
        )
),
differences AS (
  SELECT 'Asian'            AS race, g_asian   - b_asian   AS diff FROM google JOIN bls USING(id) UNION ALL
  SELECT 'Black',               g_black   - b_black   FROM google JOIN bls USING(id) UNION ALL
  SELECT 'Hispanic/Latinx',     g_hispanic - b_hispanic FROM google JOIN bls USING(id) UNION ALL
  SELECT 'White',               g_white   - b_white   FROM google JOIN bls USING(id)
)
SELECT
  race,
  ROUND(diff, 4) AS pct_difference
FROM differences
ORDER BY ABS(diff) DESC
LIMIT 3;