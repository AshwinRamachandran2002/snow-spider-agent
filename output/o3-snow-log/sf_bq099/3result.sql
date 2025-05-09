WITH filtered AS (   -- 1) keep only records that have a CPC code beginning with A01B3
    SELECT DISTINCT
           ah.value:"name"::string                                  AS assignee_name ,
           p."application_number"                                   AS application_number ,
           p."country_code"                                         AS country_code ,
           COALESCE(NULLIF(p."filing_date",0), p."publication_date") AS raw_date
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc")                 cc
         , LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE cc.value:"code"::string LIKE 'A01B3%'     -- CPC class A01B3…
      AND ah.value:"name"::string IS NOT NULL
      AND p."application_number"  IS NOT NULL
),

assignee_apps AS (   -- 2) one row per (assignee , application)
    SELECT DISTINCT
           assignee_name ,
           application_number ,
           country_code ,
           FLOOR(raw_date/10000)::INT                              AS year     -- yyyy
    FROM filtered
    WHERE raw_date IS NOT NULL AND raw_date > 0
),

assignee_totals AS ( -- 3) total applications per assignee
    SELECT assignee_name ,
           COUNT(DISTINCT application_number)                      AS total_apps
    FROM   assignee_apps
    GROUP  BY assignee_name
),

top_assignees AS (   -- 4) keep top-3 assignees
    SELECT assignee_name ,
           total_apps
    FROM (
          SELECT assignee_name ,
                 total_apps ,
                 ROW_NUMBER() OVER (ORDER BY total_apps DESC NULLS LAST) AS rn
          FROM   assignee_totals
         )
    WHERE rn <= 3
),

year_counts AS (     -- 5) applications per year for each of the top-3 assignees
    SELECT aa.assignee_name ,
           aa.year ,
           COUNT(DISTINCT aa.application_number)                   AS apps_in_year
    FROM   assignee_apps  aa
           JOIN top_assignees ta
             ON ta.assignee_name = aa.assignee_name
    GROUP  BY aa.assignee_name , aa.year
),

best_year AS (       -- 6) year with most applications for each assignee
    SELECT assignee_name ,
           year ,
           apps_in_year
    FROM (
          SELECT assignee_name ,
                 year ,
                 apps_in_year ,
                 ROW_NUMBER() OVER (PARTITION BY assignee_name
                                    ORDER BY apps_in_year DESC NULLS LAST , year) AS rn
          FROM year_counts
         )
    WHERE rn = 1
),

country_counts AS (  -- 7) country split inside that best year
    SELECT aa.assignee_name ,
           aa.country_code ,
           COUNT(DISTINCT aa.application_number)                   AS apps_country
    FROM   assignee_apps aa
           JOIN best_year byr
             ON byr.assignee_name = aa.assignee_name
            AND byr.year          = aa.year
    GROUP  BY aa.assignee_name , aa.country_code
),

best_country AS (    -- 8) country with most apps in best year
    SELECT assignee_name ,
           country_code
    FROM (
          SELECT assignee_name ,
                 country_code ,
                 apps_country ,
                 ROW_NUMBER() OVER (PARTITION BY assignee_name
                                    ORDER BY apps_country DESC NULLS LAST , country_code) AS rn
          FROM country_counts
         )
    WHERE rn = 1
)

-- 9) final result
SELECT ta.assignee_name                       AS "ASSIGNEE_NAME" ,
       ta.total_apps                          AS "TOTAL_APPLICATIONS" ,
       byr.year                               AS "TOP_YEAR" ,
       byr.apps_in_year                       AS "APPLICATIONS_IN_TOP_YEAR" ,
       bc.country_code                        AS "TOP_COUNTRY_CODE"
FROM   top_assignees ta
       JOIN best_year    byr ON byr.assignee_name = ta.assignee_name
       JOIN best_country bc  ON bc.assignee_name  = ta.assignee_name
ORDER  BY ta.total_apps DESC NULLS LAST;