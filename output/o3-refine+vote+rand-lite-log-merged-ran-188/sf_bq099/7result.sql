WITH "CTE" AS (   -- all applications classified in CPC class A01B3
    SELECT DISTINCT
        p."application_number"                                              AS "application_number",
        p."country_code"                                                    AS "country_code",
        FLOOR( COALESCE(p."filing_date", p."publication_date") / 10000 )    AS "year",
        ass.value:"name"::STRING                                            AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN ( INPUT => p."cpc")                cpc_f
         ,LATERAL FLATTEN ( INPUT => p."assignee_harmonized") ass
    WHERE cpc_f.value:"code"::STRING LIKE 'A01B3%'          -- CPC class A01B3
      AND ass.value:"name"            IS NOT NULL
      AND COALESCE(p."filing_date", p."publication_date")   IS NOT NULL
),

/* top‑3 assignees by total number of applications */
"TOP_ASSIGNEES" AS (
    SELECT
        "assignee_name",
        COUNT(DISTINCT "application_number") AS "total_apps"
    FROM "CTE"
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST, "assignee_name"
    LIMIT 3
),

/* application counts per year for the top assignees */
"YEAR_COUNTS" AS (
    SELECT
        c."assignee_name",
        c."year",
        COUNT(DISTINCT c."application_number") AS "apps_in_year"
    FROM "CTE"               c
    JOIN "TOP_ASSIGNEES"     t  ON t."assignee_name" = c."assignee_name"
    GROUP BY c."assignee_name", c."year"
),

/* for each assignee, keep the year with the most applications */
"PEAK_YEAR" AS (
    SELECT
        yc.*,
        ROW_NUMBER() OVER (PARTITION BY "assignee_name"
                           ORDER BY "apps_in_year" DESC NULLS LAST, "year") AS rn
    FROM "YEAR_COUNTS" yc
),

/* application counts by country code within the peak year */
"COUNTRY_COUNTS" AS (
    SELECT
        c."assignee_name",
        c."year",
        c."country_code",
        COUNT(DISTINCT c."application_number") AS "apps_in_country_year"
    FROM "CTE"               c
    JOIN "PEAK_YEAR"         py ON py.rn = 1
                               AND py."assignee_name" = c."assignee_name"
                               AND py."year"          = c."year"
    GROUP BY c."assignee_name", c."year", c."country_code"
),

/* for each assignee‑year, keep the country with the most applications */
"TOP_COUNTRY" AS (
    SELECT
        cc.*,
        ROW_NUMBER() OVER (PARTITION BY "assignee_name","year"
                           ORDER BY "apps_in_country_year" DESC NULLS LAST,
                                    "country_code") AS rn
    FROM "COUNTRY_COUNTS" cc
)

SELECT
    ta."assignee_name"               AS "Assignee",
    ta."total_apps"                  AS "Total_Applications",
    py."year"                        AS "Peak_Year",
    py."apps_in_year"                AS "Applications_in_Peak_Year",
    tc."country_code"                AS "Top_Country_Code_in_Peak_Year"
FROM "TOP_ASSIGNEES"  ta
JOIN "PEAK_YEAR"      py ON py.rn = 1 AND py."assignee_name" = ta."assignee_name"
JOIN "TOP_COUNTRY"    tc ON tc.rn = 1 AND tc."assignee_name" = ta."assignee_name"
                        AND tc."year"          = py."year"
ORDER BY ta."total_apps" DESC NULLS LAST, ta."assignee_name";