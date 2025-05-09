/*  Top 3 races with the greatest 2021 hiring-share gap  
    between Google (overall) and BLS tech-sector average            */

WITH google_2021 AS (          -- Google overall hiring, 2021
  SELECT
    race_asian           AS g_asian ,
    race_black           AS g_black ,
    race_hispanic_latinx AS g_hispanic ,
    race_white           AS g_white
  FROM `bigquery-public-data.google_dei.dar_non_intersectional_hiring`
  WHERE workforce = 'overall'
    AND report_year = 2021
),

bls_tech_2021 AS (            -- BLS tech-sector rows, 2021
  SELECT
    AVG(percent_asian)                    AS b_asian ,
    AVG(percent_black_or_african_american)AS b_black ,
    AVG(percent_hispanic_or_latino)       AS b_hispanic ,
    AVG(percent_white)                    AS b_white
  FROM `bigquery-public-data.bls.cpsaat18`
  WHERE year = 2021
    AND (
          -- Internet publishing & web search portals
          LOWER(COALESCE(industry,''))       LIKE '%internet publishing%' OR
          LOWER(COALESCE(industry_group,'')) LIKE '%internet publishing%' OR
          LOWER(COALESCE(industry,''))       LIKE '%web search%'           OR
          LOWER(COALESCE(industry_group,'')) LIKE '%web search%'           OR
          -- Software publishers
          ( (LOWER(COALESCE(industry,''))       LIKE '%software%'  OR
             LOWER(COALESCE(industry_group,'')) LIKE '%software%')
            AND
            (LOWER(COALESCE(industry,''))       LIKE '%publisher%' OR
             LOWER(COALESCE(industry_group,'')) LIKE '%publisher%') )      OR
          -- Data processing, hosting & related services
          ( (LOWER(COALESCE(industry,''))       LIKE '%data processing%'  OR
             LOWER(COALESCE(industry_group,'')) LIKE '%data processing%')
            AND
            (LOWER(COALESCE(industry,''))       LIKE '%hosting%'          OR
             LOWER(COALESCE(industry_group,'')) LIKE '%hosting%') )       OR
          -- Computer systems design & related services
          LOWER(COALESCE(industry,''))       LIKE '%computer systems design%' OR
          LOWER(COALESCE(industry_group,'')) LIKE '%computer systems design%'
        )
),

diffs AS (                     -- assemble race-by-race gaps
  SELECT 'Asian'                     AS race , g_asian    - b_asian    AS gap FROM google_2021, bls_tech_2021 UNION ALL
  SELECT 'Black or African American' AS race , g_black    - b_black    AS gap FROM google_2021, bls_tech_2021 UNION ALL
  SELECT 'Hispanic or Latinx'        AS race , g_hispanic - b_hispanic AS gap FROM google_2021, bls_tech_2021 UNION ALL
  SELECT 'White'                     AS race , g_white    - b_white    AS gap FROM google_2021, bls_tech_2021
)

SELECT race,
       gap AS percentage_difference
FROM diffs
ORDER BY ABS(gap) DESC
LIMIT 3;