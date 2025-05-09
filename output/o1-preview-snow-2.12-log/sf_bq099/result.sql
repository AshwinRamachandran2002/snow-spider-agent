WITH cte_applications AS (
    SELECT f_assignee.value:"name"::STRING AS "Assignee_Name",
           EXTRACT(YEAR FROM TRY_TO_DATE(t."publication_date"::STRING, 'YYYYMMDD')) AS "Year",
           t."country_code" AS "Country_Code"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS" t,
         LATERAL FLATTEN(INPUT => t."cpc") f_cpc,
         LATERAL FLATTEN(INPUT => t."assignee_harmonized") f_assignee
    WHERE f_cpc.value:"code"::STRING LIKE 'A01B3%'
      AND TRY_TO_DATE(t."publication_date"::STRING, 'YYYYMMDD') IS NOT NULL
),

cte_total_applications AS (
    SELECT "Assignee_Name",
           COUNT(*) AS "Total_Number_of_Applications"
    FROM cte_applications
    GROUP BY "Assignee_Name"
),

cte_top_assignees AS (
    SELECT "Assignee_Name",
           "Total_Number_of_Applications"
    FROM cte_total_applications
    ORDER BY "Total_Number_of_Applications" DESC NULLS LAST
    LIMIT 3
),

cte_assignee_year_counts AS (
    SELECT "Assignee_Name",
           "Year",
           COUNT(*) AS "Number_of_Applications_in_that_Year"
    FROM cte_applications
    WHERE "Assignee_Name" IN (SELECT "Assignee_Name" FROM cte_top_assignees)
    GROUP BY "Assignee_Name", "Year"
),

cte_top_year_per_assignee AS (
    SELECT * FROM (
        SELECT "Assignee_Name",
               "Year" AS "Year_With_Most_Applications",
               "Number_of_Applications_in_that_Year",
               ROW_NUMBER() OVER (PARTITION BY "Assignee_Name" ORDER BY "Number_of_Applications_in_that_Year" DESC NULLS LAST) AS rn
        FROM cte_assignee_year_counts
    )
    WHERE rn = 1
),

cte_assignee_year_country_counts AS (
    SELECT "Assignee_Name",
           "Year",
           "Country_Code",
           COUNT(*) AS "Applications_in_Country"
    FROM cte_applications
    WHERE "Assignee_Name" IN (SELECT "Assignee_Name" FROM cte_top_assignees)
      AND "Year" IN (SELECT "Year_With_Most_Applications" FROM cte_top_year_per_assignee)
    GROUP BY "Assignee_Name", "Year", "Country_Code"
),

cte_top_country_per_assignee_year AS (
    SELECT * FROM (
        SELECT "Assignee_Name",
               "Year",
               "Country_Code" AS "Country_Code_With_Most_Applications_During_That_Year",
               ROW_NUMBER() OVER (PARTITION BY "Assignee_Name", "Year" ORDER BY "Applications_in_Country" DESC NULLS LAST) AS rn
        FROM cte_assignee_year_country_counts
    )
    WHERE rn = 1
)

SELECT
    ta."Assignee_Name",
    ta."Total_Number_of_Applications",
    ty."Year_With_Most_Applications",
    ty."Number_of_Applications_in_that_Year",
    tc."Country_Code_With_Most_Applications_During_That_Year"
FROM cte_top_assignees ta
JOIN cte_top_year_per_assignee ty ON ta."Assignee_Name" = ty."Assignee_Name"
JOIN cte_top_country_per_assignee_year tc ON ta."Assignee_Name" = tc."Assignee_Name" AND ty."Year_With_Most_Applications" = tc."Year"
ORDER BY ta."Total_Number_of_Applications" DESC NULLS LAST;