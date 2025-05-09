/*-- Top-3 races with the greatest 2021 %-point hiring gap 
      between Google overall hiring and BLS tech-sector averages --*/

WITH
/*--------------------------------------------------------------------
  1) Google 2021 overall-workforce hiring percentages
--------------------------------------------------------------------*/
google AS (
  SELECT 
      "race_asian"            AS g_asian ,
      "race_black"            AS g_black ,
      "race_hispanic_latinx"  AS g_hisp ,
      "race_white"            AS g_white
  FROM   GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
  WHERE  "report_year" = 2021
    AND  "workforce"   ILIKE '%overall%'
  LIMIT 1
),

/*--------------------------------------------------------------------
  2) BLS 2021 tech-sector race averages for the four specified groups
--------------------------------------------------------------------*/
bls AS (
  SELECT
      AVG("percent_asian")                     AS b_asian ,
      AVG("percent_black_or_african_american") AS b_black ,
      AVG("percent_hispanic_or_latino")        AS b_hisp ,
      AVG("percent_white")                     AS b_white
  FROM   GOOGLE_DEI.BLS.CPSAAT18
  WHERE  "year" = 2021
    AND (
         /* Internet publishing & web-search portals */
         (   ("subsector"      ILIKE '%internet%' AND "subsector"      ILIKE '%publish%')
          OR ("industry_group" ILIKE '%internet%' AND "industry_group" ILIKE '%publish%')
          OR ("industry"       ILIKE '%internet%' AND "industry"       ILIKE '%publish%') )

      OR /* Software publishers */
         (   ("subsector"      ILIKE '%software%' AND "subsector"      ILIKE '%publish%')
          OR ("industry_group" ILIKE '%software%' AND "industry_group" ILIKE '%publish%')
          OR ("industry"       ILIKE '%software%' AND "industry"       ILIKE '%publish%') )

      OR /* Data processing, hosting, and related services */
         (   (("subsector"      ILIKE '%data%' AND "subsector"      ILIKE '%process%')
              OR  "subsector"      ILIKE '%hosting%')
          OR (("industry_group" ILIKE '%data%' AND "industry_group" ILIKE '%process%')
              OR  "industry_group" ILIKE '%hosting%')
          OR (("industry"       ILIKE '%data%' AND "industry"       ILIKE '%process%')
              OR  "industry"       ILIKE '%hosting%') )

      OR /* Computer systems design and related services */
         (   "industry_group" ILIKE '%computer%systems%design%'
          OR "industry"       ILIKE '%computer%systems%design%'
          OR ("industry_group" ILIKE '%computer%' AND "industry_group" ILIKE '%systems%')
          OR ("industry"       ILIKE '%computer%' AND "industry"       ILIKE '%systems%') )
    )
),

/*--------------------------------------------------------------------
  3) Combine, compute %-point differences, unpivot to one row per race
--------------------------------------------------------------------*/
gaps AS (
  SELECT 'Asian'    AS race , (g.g_asian - b.b_asian) * 100 AS diff_pct_pts FROM google g CROSS JOIN bls b
  UNION ALL
  SELECT 'Black'    AS race , (g.g_black - b.b_black) * 100 FROM google g CROSS JOIN bls b
  UNION ALL
  SELECT 'Hispanic/Latinx' AS race , (g.g_hisp  - b.b_hisp) * 100 FROM google g CROSS JOIN bls b
  UNION ALL
  SELECT 'White'    AS race , (g.g_white - b.b_white) * 100 FROM google g CROSS JOIN bls b
)

/*--------------------------------------------------------------------
  4) Return top-3 by absolute gap
--------------------------------------------------------------------*/
SELECT 
    race,
    ROUND(diff_pct_pts,4) AS difference_percentage_points
FROM   gaps
ORDER  BY ABS(diff_pct_pts) DESC NULLS LAST
LIMIT  3;