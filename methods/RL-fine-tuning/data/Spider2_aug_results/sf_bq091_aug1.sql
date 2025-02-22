-- Task: Which assignee has filed the most applications in the patent category 'A61'?
WITH AA AS (
    SELECT 
        FIRST_VALUE("assignee_harmonized") OVER (PARTITION BY "application_number" ORDER BY "application_number") AS assignee_harmonized,
        "application_number"
    FROM 
        PATENTS.PATENTS.PUBLICATIONS AS pubs,
        LATERAL FLATTEN(input => pubs."cpc") AS c
    WHERE 
        c.value:"code" LIKE 'A61%'
),
PatentApplications AS (
    SELECT 
        ANY_VALUE(assignee_harmonized) AS assignee_harmonized
    FROM AA
    GROUP BY "application_number"
),
AssigneeApplications AS (
    SELECT 
        COUNT(*) AS total_applications,
        a.value::STRING AS assignee_name
    FROM 
        PatentApplications,
        LATERAL FLATTEN(input => assignee_harmonized) AS a
    GROUP BY 
        a.value::STRING
)
SELECT
    assignee_name
FROM 
    AssigneeApplications
ORDER BY 
    total_applications DESC
LIMIT 1