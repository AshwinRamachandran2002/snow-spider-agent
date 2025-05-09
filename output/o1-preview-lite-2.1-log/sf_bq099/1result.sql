WITH ipc_data AS (
    SELECT t."publication_number",
        t."publication_date",
        t."country_code",
        assignee_f.value:"name"::STRING AS "assignee_name",
        ipc_f.value:"code"::STRING AS "ipc_code",
        FLOOR(t."publication_date" / 10000) AS "publication_year"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
        LATERAL FLATTEN(input => t."assignee_harmonized") assignee_f,
        LATERAL FLATTEN(input => t."ipc") ipc_f
    WHERE ipc_f.value:"code"::STRING ILIKE 'A01B3%'
),
total_apps AS (
    SELECT "assignee_name",
        COUNT(DISTINCT "publication_number") AS "total_applications"
    FROM ipc_data
    GROUP BY "assignee_name"
),
top_assignees AS (
    SELECT "assignee_name", "total_applications"
    FROM total_apps
    ORDER BY "total_applications" DESC NULLS LAST
    LIMIT 3
),
assignee_top_year AS (
    SELECT "assignee_name", "publication_year", "applications_in_year"
    FROM (
        SELECT "assignee_name",
            "publication_year",
            COUNT(DISTINCT "publication_number") AS "applications_in_year",
            ROW_NUMBER() OVER (
                PARTITION BY "assignee_name"
                ORDER BY COUNT(DISTINCT "publication_number") DESC, "publication_year" ASC
            ) AS "rn"
        FROM ipc_data
        WHERE "assignee_name" IN (SELECT "assignee_name" FROM top_assignees)
        GROUP BY "assignee_name", "publication_year"
    ) sub
    WHERE "rn" = 1
),
assignee_top_country AS (
    SELECT "assignee_name", "publication_year", "country_code"
    FROM (
        SELECT "assignee_name",
            "publication_year",
            "country_code",
            COUNT(DISTINCT "publication_number") AS "applications_in_country",
            ROW_NUMBER() OVER (
                PARTITION BY "assignee_name", "publication_year"
                ORDER BY COUNT(DISTINCT "publication_number") DESC, "country_code" ASC
            ) AS "rn"
        FROM ipc_data
        WHERE ("assignee_name", "publication_year") IN (SELECT "assignee_name", "publication_year" FROM assignee_top_year)
        GROUP BY "assignee_name", "publication_year", "country_code"
    ) sub
    WHERE "rn" = 1
)
SELECT
    t."assignee_name" AS "Assignee_Name",
    t."total_applications" AS "Total_Applications",
    y."publication_year" AS "Year_With_Most_Applications",
    y."applications_in_year" AS "Applications_In_That_Year",
    c."country_code" AS "Country_Code_With_Most_Applications"
FROM top_assignees t
JOIN assignee_top_year y ON t."assignee_name" = y."assignee_name"
LEFT JOIN assignee_top_country c ON y."assignee_name" = c."assignee_name" AND y."publication_year" = c."publication_year"
ORDER BY t."total_applications" DESC NULLS LAST, t."assignee_name";