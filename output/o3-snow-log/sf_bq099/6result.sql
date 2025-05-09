/* ---------------------------------------------------------------
   TOP-3 ASSIGNEES FOR CPC CLASS “A01B3 …”
   ----------------------------------------------------------------*/
WITH
/* 1.  Publications that carry a CPC code starting with ‘A01B3’     */
filtered AS (   
    SELECT
        p."application_number"                                    AS app_no,
        COALESCE(p."application_number_formatted",p."application_number") AS app_no_fmt,
        p."filing_date"                                           AS filing_date,
        p."country_code"                                          AS country_code,
        ass.value:"name"::STRING                                  AS assignee_name,
        cp.value:"code"::STRING                                   AS cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")         cp            -- unfold CPC codes
         ,LATERAL FLATTEN(input => p."assignee_harmonized") ass   -- unfold assignees
    WHERE cp.value:"code"::STRING LIKE 'A01B3%'                   -- keep only A01B3…
          AND p."application_number" IS NOT NULL                  -- need an application id
          AND p."filing_date"      > 0                            -- keep sensible dates
)
/* 2.  Top-3 assignees by total number of applications             */
,top_assignees AS (           
    SELECT
        assignee_name,
        COUNT(DISTINCT app_no)           AS total_apps
    FROM filtered
    GROUP BY assignee_name
    ORDER BY total_apps DESC NULLS LAST
    LIMIT 3
)
/* 3.  For those assignees: application counts per year            */
,apps_per_year AS (
    SELECT
        f.assignee_name,
        FLOOR(f.filing_date/10000)       AS yr,
        COUNT(DISTINCT f.app_no)         AS apps_in_year
    FROM filtered f
    JOIN top_assignees t
          ON f.assignee_name = t.assignee_name
    GROUP BY f.assignee_name, yr
)
/* 4.  Peak year (year with most applications) for each assignee   */
,peak_year AS (
    SELECT *
    FROM (
        SELECT
            a.assignee_name,
            a.yr,
            a.apps_in_year,
            ROW_NUMBER() OVER (PARTITION BY a.assignee_name
                               ORDER BY a.apps_in_year DESC NULLS LAST, a.yr) AS rn
        FROM apps_per_year a
    )
    WHERE rn = 1
)
/* 5.  Within that peak year: country with most applications       */
,country_peak AS (
    SELECT *
    FROM (
        SELECT
            f.assignee_name,
            FLOOR(f.filing_date/10000)   AS yr,
            f.country_code,
            COUNT(DISTINCT f.app_no)     AS apps_in_country,
            ROW_NUMBER() OVER (PARTITION BY f.assignee_name, FLOOR(f.filing_date/10000)
                               ORDER BY COUNT(DISTINCT f.app_no) DESC NULLS LAST,
                                        f.country_code)            AS rn
        FROM filtered f
        JOIN peak_year p
              ON p.assignee_name = f.assignee_name
             AND p.yr            = FLOOR(f.filing_date/10000)
        GROUP BY f.assignee_name, FLOOR(f.filing_date/10000), f.country_code
    )
    WHERE rn = 1
)
/* 6.  Assemble the requested result                               */
SELECT
    ta.assignee_name                              AS "ASSIGNEE_NAME",
    ta.total_apps                                 AS "TOTAL_APPLICATIONS",
    py.yr                                         AS "PEAK_YEAR",
    py.apps_in_year                               AS "APPLICATIONS_IN_PEAK_YEAR",
    cp.country_code                               AS "TOP_COUNTRY_CODE_IN_PEAK_YEAR"
FROM top_assignees ta
JOIN peak_year     py  ON py.assignee_name = ta.assignee_name
JOIN country_peak   cp ON cp.assignee_name = ta.assignee_name
                      AND cp.yr            = py.yr
ORDER BY ta.total_apps DESC NULLS LAST;