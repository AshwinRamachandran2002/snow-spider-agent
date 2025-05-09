/* 
  2021 – Racial & Gender distribution comparison  
  • Google overall workforce – Hiring  
  • Google overall workforce – Representation  
  • BLS technology sectors – “Internet publishing … web search portals” OR 
    “Computer systems design and related services” (employment-weighted average) 
*/

WITH google_hiring AS (          -- Google overall workforce HIRING (2021)
    SELECT
        'Google Hiring'                             AS "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_HIRING
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
),

google_representation AS (       -- Google overall workforce REPRESENTATION (2021)
    SELECT
        'Google Representation'                    AS "source",
        "race_asian",
        "race_black",
        "race_hispanic_latinx",
        "race_white",
        "gender_us_women",
        "gender_us_men"
    FROM GOOGLE_DEI.GOOGLE_DEI.DAR_NON_INTERSECTIONAL_REPRESENTATION
    WHERE "workforce" = 'overall'
      AND "report_year" = 2021
),

bls_tech_rows AS (               -- BLS CPSAAT18 2021 tech-sector rows
    SELECT
        "total_employed_in_thousands"                             AS emp,
        "percent_asian"                                           AS race_asian,
        "percent_black_or_african_american"                       AS race_black,
        "percent_hispanic_or_latino"                              AS race_hispanic_latinx,
        "percent_white"                                           AS race_white,
        "percent_women"                                           AS gender_us_women
    FROM GOOGLE_DEI.BLS.CPSAAT18
    WHERE "year" = 2021
      AND (
             /* Internet publishing & web search portals */
             "subsector"      ILIKE '%internet publishing and broadcasting and web search portals%' OR
             "industry_group" ILIKE '%internet publishing and broadcasting and web search portals%' OR
             "industry"       ILIKE '%internet publishing and broadcasting and web search portals%' OR
             /* Computer systems design & related services */
             "subsector"      ILIKE '%computer systems design and related services%'               OR
             "industry_group" ILIKE '%computer systems design and related services%'               OR
             "industry"       ILIKE '%computer systems design and related services%'
          )
),

bls_tech_agg AS (                -- Employment-weighted averages → single row
    SELECT
        'BLS Tech Sectors'                             AS "source",
        SUM(race_asian          * emp) / SUM(emp)      AS race_asian,
        SUM(race_black          * emp) / SUM(emp)      AS race_black,
        SUM(race_hispanic_latinx* emp) / SUM(emp)      AS race_hispanic_latinx,
        SUM(race_white          * emp) / SUM(emp)      AS race_white,
        SUM(gender_us_women     * emp) / SUM(emp)      AS gender_us_women,
        1 - (SUM(gender_us_women* emp) / SUM(emp))     AS gender_us_men
    FROM bls_tech_rows
)

-- Combine the three sources
SELECT * FROM google_hiring
UNION ALL
SELECT * FROM google_representation
UNION ALL
SELECT * FROM bls_tech_agg
ORDER BY "source";