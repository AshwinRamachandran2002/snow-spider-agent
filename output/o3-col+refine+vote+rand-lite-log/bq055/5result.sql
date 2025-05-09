-- Top-3 races whose 2021 Google-hiring share differs most from the
-- average 2021 BLS share for the four specified tech-industry categories
WITH bls_tech AS (   -- 2021 BLS rows that match any of the four tech patterns
  SELECT
    percent_white,
    percent_black_or_african_american,
    percent_asian,
    percent_hispanic_or_latino
  FROM `bigquery-public-data.google_dei.full_csv-latest-data-is-2023`
  WHERE year = 2021
    AND (
      -- Internet publishing & broadcasting & web search portals
      LOWER(COALESCE(sector,''))          LIKE '%internet publishing and broadcasting and web search portals%' OR
      LOWER(COALESCE(subsector,''))       LIKE '%internet publishing and broadcasting and web search portals%' OR
      LOWER(COALESCE(industry_group,''))  LIKE '%internet publishing and broadcasting and web search portals%' OR
      LOWER(COALESCE(industry,''))        LIKE '%internet publishing and broadcasting and web search portals%' OR
      -- Software publishers
      LOWER(COALESCE(sector,''))          LIKE '%software publishers%' OR
      LOWER(COALESCE(subsector,''))       LIKE '%software publishers%' OR
      LOWER(COALESCE(industry_group,''))  LIKE '%software publishers%' OR
      LOWER(COALESCE(industry,''))        LIKE '%software publishers%' OR
      -- Data processing, hosting, and related services
      LOWER(COALESCE(sector,''))          LIKE '%data processing, hosting, and related services%' OR
      LOWER(COALESCE(subsector,''))       LIKE '%data processing, hosting, and related services%' OR
      LOWER(COALESCE(industry_group,''))  LIKE '%data processing, hosting, and related services%' OR
      LOWER(COALESCE(industry,''))        LIKE '%data processing, hosting, and related services%' OR
      -- Computer systems design and related services
      LOWER(COALESCE(sector,''))          LIKE '%computer systems design and related services%' OR
      LOWER(COALESCE(subsector,''))       LIKE '%computer systems design and related services%' OR
      LOWER(COALESCE(industry_group,''))  LIKE '%computer systems design and related services%' OR
      LOWER(COALESCE(industry,''))        LIKE '%computer systems design and related services%'
    )
),
avg_bls AS (         -- average race shares across the four tech categories
  SELECT
    AVG(percent_white)                   AS white,
    AVG(percent_black_or_african_american) AS black,
    AVG(percent_asian)                  AS asian,
    AVG(percent_hispanic_or_latino)     AS hispanic_latinx
  FROM bls_tech
),
google AS (          -- Google 2021 overall hiring race shares
  SELECT
    race_white            AS white,
    race_black            AS black,
    race_asian            AS asian,
    race_hispanic_latinx  AS hispanic_latinx
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE report_year = 2021
    AND workforce   = 'overall'
),
race_diff AS (       -- pivot to rows and compute absolute differences
  SELECT 'white'            AS race, g.white            AS google_pct, b.white            AS bls_pct FROM google g CROSS JOIN avg_bls b
  UNION ALL
  SELECT 'black',            g.black,                    b.black            FROM google g CROSS JOIN avg_bls b
  UNION ALL
  SELECT 'asian',            g.asian,                    b.asian            FROM google g CROSS JOIN avg_bls b
  UNION ALL
  SELECT 'hispanic_latinx',  g.hispanic_latinx,          b.hispanic_latinx  FROM google g CROSS JOIN avg_bls b
)
SELECT
  race,
  ABS(google_pct - bls_pct) AS pct_difference
FROM race_diff
ORDER BY pct_difference DESC
LIMIT 3;