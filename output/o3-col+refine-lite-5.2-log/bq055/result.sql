-- Top‑3 races with the largest Google‑minus‑BLS hiring percentage gaps (2021)
WITH bls_tech AS (
  SELECT AVG(percent_white)                    AS bls_white ,
         AVG(percent_black_or_african_american)AS bls_black,
         AVG(percent_asian)                    AS bls_asian,
         AVG(percent_hispanic_or_latino)       AS bls_hispanic
  FROM  `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
         -- Internet publishing / web search portals
         LOWER(sector)         LIKE '%internet publishing%'      OR
         LOWER(subsector)      LIKE '%internet publishing%'      OR
         LOWER(industry_group) LIKE '%internet publishing%'      OR
         LOWER(industry)       LIKE '%internet publishing%'      OR
         LOWER(sector)         LIKE '%web search portal%'        OR
         LOWER(subsector)      LIKE '%web search portal%'        OR
         LOWER(industry_group) LIKE '%web search portal%'        OR
         LOWER(industry)       LIKE '%web search portal%'        OR
         -- Software publishers
         LOWER(sector)         LIKE '%software publisher%'       OR
         LOWER(subsector)      LIKE '%software publisher%'       OR
         LOWER(industry_group) LIKE '%software publisher%'       OR
         LOWER(industry)       LIKE '%software publisher%'       OR
         -- Data processing, hosting, and related services
         LOWER(sector)         LIKE '%data processing%'          OR
         LOWER(subsector)      LIKE '%data processing%'          OR
         LOWER(industry_group) LIKE '%data processing%'          OR
         LOWER(industry)       LIKE '%data processing%'          OR
         -- Computer systems design and related services
         LOWER(sector)         LIKE '%computer systems design%'  OR
         LOWER(subsector)      LIKE '%computer systems design%'  OR
         LOWER(industry_group) LIKE '%computer systems design%'  OR
         LOWER(industry)       LIKE '%computer systems design%'
        )
),
google_2021 AS (
  SELECT race_white           AS g_white,
         race_black           AS g_black,
         race_asian           AS g_asian,
         race_hispanic_latinx AS g_hispanic
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce   = 'overall'
),
gaps AS (
  SELECT 'White'           AS race, g_white   - bls_white    AS gap FROM google_2021, bls_tech UNION ALL
  SELECT 'Black'           AS race, g_black   - bls_black    AS gap FROM google_2021, bls_tech UNION ALL
  SELECT 'Asian'           AS race, g_asian   - bls_asian    AS gap FROM google_2021, bls_tech UNION ALL
  SELECT 'Hispanic/Latinx' AS race, g_hispanic- bls_hispanic AS gap FROM google_2021, bls_tech
)
SELECT race,
       gap,
       ABS(gap) AS abs_gap
FROM   gaps
ORDER  BY abs_gap DESC
LIMIT 3;