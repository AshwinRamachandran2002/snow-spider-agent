/*  Combined 2021 racial & U.S.-gender distribution report
    – Google overall hiring
    – Google overall representation
    – BLS technology sector (Internet-publishing / Computer-systems-design)           */

SELECT *
FROM (
        /*--------------- 1. Google – OVERALL WORKFORCE HIRING (2021) ---------------*/
        SELECT
               'Google_Hiring'                                      AS "source",
               "race_asian",
               "race_black",
               "race_hispanic_latinx",
               "race_white",
               "gender_us_women",
               "gender_us_men"
        FROM   GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
        WHERE  "workforce"   = 'overall'
          AND  "report_year" = 2021

        UNION ALL

        /*----------- 2. Google – OVERALL WORKFORCE REPRESENTATION (2021) ----------*/
        SELECT
               'Google_Representation'                              AS "source",
               "race_asian",
               "race_black",
               "race_hispanic_latinx",
               "race_white",
               "gender_us_women",
               "gender_us_men"
        FROM   GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
        WHERE  "workforce"   = 'overall'
          AND  "report_year" = 2021

        UNION ALL

        /*------------------- 3. BLS – U.S. TECHNOLOGY SECTOR (2021) ----------------
          Tech‐sector rows are those whose Industry/Subsector/Industry-group text
          contains either
              • “internet publishing and broadcasting and web search portals”  OR
              • “computer systems design and related services”
          Figures are employment-weighted averages.                                 */
        SELECT
               'BLS_Tech_Sector'                                   AS "source",
               SUM("percent_asian"                * "total_employed_in_thousands")
                 / SUM("total_employed_in_thousands")               AS "race_asian",
               SUM("percent_black_or_african_american" * "total_employed_in_thousands")
                 / SUM("total_employed_in_thousands")               AS "race_black",
               SUM("percent_hispanic_or_latino"      * "total_employed_in_thousands")
                 / SUM("total_employed_in_thousands")               AS "race_hispanic_latinx",
               SUM("percent_white"                  * "total_employed_in_thousands")
                 / SUM("total_employed_in_thousands")               AS "race_white",
               SUM("percent_women"                  * "total_employed_in_thousands")
                 / SUM("total_employed_in_thousands")               AS "gender_us_women",
               1
                 - SUM("percent_women" * "total_employed_in_thousands")
                   / SUM("total_employed_in_thousands")             AS "gender_us_men"
        FROM   GOOGLE_DEI.BLS.CPSAAT18
        WHERE  "year" = 2021
          AND (
                 /* Internet-publishing & web-search portals */
                 (   "industry"       ILIKE '%internet publishing%'        AND
                     "industry"       ILIKE '%web search portals%'           )
              OR (   "subsector"      ILIKE '%internet publishing%'        AND
                     "subsector"      ILIKE '%web search portals%'          )
              OR (   "industry_group" ILIKE '%internet publishing%'        AND
                     "industry_group" ILIKE '%web search portals%'          )
                 /* Computer-systems-design & related services */
              OR   "industry"        ILIKE '%computer systems design%'
              OR   "subsector"       ILIKE '%computer systems design%'
              OR   "industry_group"  ILIKE '%computer systems design%'
              )
     )
ORDER BY "source";