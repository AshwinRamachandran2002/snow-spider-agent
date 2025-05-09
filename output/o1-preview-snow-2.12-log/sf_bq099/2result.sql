WITH relevant_applications AS (
    SELECT
        t."application_number",
        f1.value:"name"::STRING AS "assignee_name",
        TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') AS "filing_date",
        DATE_PART(year, TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD')) AS "filing_year",
        t."country_code"
    FROM
        "PATENTS"."PATENTS"."PUBLICATIONS" t,
        LATERAL FLATTEN(INPUT => t."cpc") f2,
        LATERAL FLATTEN(INPUT => t."assignee_harmonized") f1
    WHERE
        f2.value:"code"::STRING LIKE 'A01B3%'
        AND TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
),
assignee_totals AS (
    SELECT
        "assignee_name",
        COUNT(DISTINCT "application_number") AS "total_applications"
    FROM
        relevant_applications
    GROUP BY
        "assignee_name"
),
top_assignees AS (
    SELECT
        "assignee_name",
        "total_applications"
    FROM
        assignee_totals
    ORDER BY
        "total_applications" DESC NULLS LAST
    LIMIT 3
),
assignee_year_counts AS (
    SELECT
        ra."assignee_name",
        ra."filing_year",
        COUNT(DISTINCT ra."application_number") AS "applications_in_year"
    FROM
        relevant_applications ra
    INNER JOIN
        top_assignees ta ON ra."assignee_name" = ta."assignee_name"
    GROUP BY
        ra."assignee_name",
        ra."filing_year"
),
assignee_top_year AS (
    SELECT
        "assignee_name",
        "filing_year",
        "applications_in_year",
        ROW_NUMBER() OVER (
            PARTITION BY "assignee_name"
            ORDER BY "applications_in_year" DESC NULLS LAST, "filing_year" ASC
        ) AS rn
    FROM
        assignee_year_counts
    WHERE
        "applications_in_year" IS NOT NULL
),
assignee_year_country_counts AS (
    SELECT
        ra."assignee_name",
        ra."filing_year",
        ra."country_code",
        COUNT(DISTINCT ra."application_number") AS "applications_in_country"
    FROM
        relevant_applications ra
    INNER JOIN
        assignee_top_year aty ON
            ra."assignee_name" = aty."assignee_name"
            AND ra."filing_year" = aty."filing_year"
            AND aty.rn = 1
    WHERE
        aty.rn = 1
    GROUP BY
        ra."assignee_name",
        ra."filing_year",
        ra."country_code"
),
assignee_year_top_country AS (
    SELECT
        aycc."assignee_name",
        aycc."filing_year",
        aycc."country_code",
        aycc."applications_in_country",
        ROW_NUMBER() OVER (
            PARTITION BY aycc."assignee_name", aycc."filing_year"
            ORDER BY aycc."applications_in_country" DESC NULLS LAST, aycc."country_code" ASC
        ) AS rn
    FROM
        assignee_year_country_counts aycc
    WHERE
        aycc."applications_in_country" IS NOT NULL
)
SELECT
    ta."assignee_name" AS "Assignee_Name",
    ta."total_applications" AS "Total_Number_of_Applications",
    aty."filing_year" AS "Year_With_Most_Applications",
    aty."applications_in_year" AS "Number_of_Applications_in_that_Year",
    aytc."country_code" AS "Country_Code_With_Most_Applications_During_That_Year"
FROM
    top_assignees ta
INNER JOIN
    assignee_top_year aty ON
        ta."assignee_name" = aty."assignee_name"
        AND aty.rn = 1
INNER JOIN
    assignee_year_top_country aytc ON
        aytc."assignee_name" = aty."assignee_name"
        AND aytc."filing_year" = aty."filing_year"
        AND aytc.rn = 1
ORDER BY
    ta."total_applications" DESC NULLS LAST;