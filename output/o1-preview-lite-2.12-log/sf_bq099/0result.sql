WITH AssigneeTotalApplications AS (
    SELECT
        assignee.value::VARIANT:"name"::STRING AS "assignee_name",
        COUNT(DISTINCT t."application_number") AS "total_applications"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" t
        , LATERAL FLATTEN(input => t."cpc") f
        , LATERAL FLATTEN(input => t."assignee_harmonized") assignee
    WHERE f.value::VARIANT:"code"::STRING LIKE 'A01B3%'
    GROUP BY "assignee_name"
),
TopAssignees AS (
    SELECT * FROM AssigneeTotalApplications
    ORDER BY "total_applications" DESC NULLS LAST
    LIMIT 3
),
AssigneeYearApplications AS (
    SELECT
        assignee.value::VARIANT:"name"::STRING AS "assignee_name",
        FLOOR(t."publication_date" / 10000) AS "publication_year",
        COUNT(DISTINCT t."application_number") AS "applications_in_year"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" t
        , LATERAL FLATTEN(input => t."cpc") f
        , LATERAL FLATTEN(input => t."assignee_harmonized") assignee
    WHERE f.value::VARIANT:"code"::STRING LIKE 'A01B3%'
    GROUP BY "assignee_name", "publication_year"
),
AssigneeMostActiveYear AS (
    SELECT
        a."assignee_name",
        a."publication_year",
        a."applications_in_year",
        ROW_NUMBER() OVER (PARTITION BY a."assignee_name" ORDER BY a."applications_in_year" DESC, a."publication_year" ASC) AS "rn"
    FROM AssigneeYearApplications a
    JOIN TopAssignees t ON a."assignee_name" = t."assignee_name"
),
AssigneeTopYear AS (
    SELECT
        "assignee_name",
        "publication_year",
        "applications_in_year"
    FROM AssigneeMostActiveYear
    WHERE "rn" = 1
),
AssigneeYearCountryApplications AS (
    SELECT
        assignee.value::VARIANT:"name"::STRING AS "assignee_name",
        FLOOR(t."publication_date" / 10000) AS "publication_year",
        t."country_code",
        COUNT(DISTINCT t."application_number") AS "applications_in_country"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" t
        , LATERAL FLATTEN(input => t."cpc") f
        , LATERAL FLATTEN(input => t."assignee_harmonized") assignee
    WHERE f.value::VARIANT:"code"::STRING LIKE 'A01B3%'
    GROUP BY "assignee_name", "publication_year", t."country_code"
),
AssigneeTopYearCountry AS (
    SELECT
        ac."assignee_name",
        ac."publication_year",
        ac."country_code",
        ac."applications_in_country",
        ROW_NUMBER() OVER(PARTITION BY ac."assignee_name" ORDER BY ac."applications_in_country" DESC, ac."country_code") AS "rn"
    FROM AssigneeYearCountryApplications ac
    JOIN AssigneeTopYear aty ON ac."assignee_name" = aty."assignee_name" AND ac."publication_year" = aty."publication_year"
),
AssigneeTopYearTopCountry AS (
    SELECT
        "assignee_name",
        "publication_year",
        "country_code"
    FROM AssigneeTopYearCountry
    WHERE "rn" = 1
),
FinalResults AS (
    SELECT
        a."assignee_name",
        ta."total_applications",
        a."publication_year" AS "year_with_most_applications",
        a."applications_in_year" AS "number_of_applications_in_that_year",
        tyc."country_code" AS "country_code_with_most_applications_during_that_year"
    FROM AssigneeTopYear a
    JOIN TopAssignees ta ON a."assignee_name" = ta."assignee_name"
    LEFT JOIN AssigneeTopYearTopCountry tyc ON a."assignee_name" = tyc."assignee_name" AND a."publication_year" = tyc."publication_year"
)
SELECT
    "Assignee_Name",
    "Total_Number_of_Applications",
    "Year_With_Most_Applications",
    "Number_of_Applications_in_that_Year",
    "Country_Code_With_Most_Applications_During_That_Year"
FROM (
    SELECT
        "assignee_name" AS "Assignee_Name",
        "total_applications" AS "Total_Number_of_Applications",
        "year_with_most_applications" AS "Year_With_Most_Applications",
        "number_of_applications_in_that_year" AS "Number_of_Applications_in_that_Year",
        "country_code_with_most_applications_during_that_year" AS "Country_Code_With_Most_Applications_During_That_Year"
    FROM FinalResults
)
ORDER BY "Total_Number_of_Applications" DESC;