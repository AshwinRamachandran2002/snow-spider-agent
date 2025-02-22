-- Task: Determine the filing year during which the assignee with the highest total number of patent applications in the 'A61' CPC category filed the most applications.
WITH AA AS (
    SELECT 
        FIRST_VALUE("assignee_harmonized") OVER (PARTITION BY "application_number" ORDER BY "application_number") AS assignee_harmonized,
        FIRST_VALUE("filing_date") OVER (PARTITION BY "application_number" ORDER BY "application_number") AS filing_date,
        "application_number"
    FROM 
        PATENTS.PATENTS.PUBLICATIONS AS pubs,
        LATERAL FLATTEN(input => pubs."cpc") AS c
    WHERE 
        c.value:"code" LIKE 'A61%'
),

PatentApplications AS (
    SELECT 
        ANY_VALUE(assignee_harmonized) AS assignee_harmonized,
        ANY_VALUE(filing_date) AS filing_date
    FROM AA
    GROUP BY "application_number"
),

AssigneeApplications AS (
    SELECT 
        COUNT(*) AS total_applications,
        a.value::STRING AS assignee_name,
        CAST(FLOOR(filing_date / 10000) AS INT) AS filing_year
    FROM 
        PatentApplications,
        LATERAL FLATTEN(input => assignee_harmonized) AS a
    GROUP BY 
        a.value::STRING, filing_year
),

TotalApplicationsPerAssignee AS (
    SELECT
        assignee_name,
        SUM(total_applications) AS total_applications
    FROM 
        AssigneeApplications
    GROUP BY 
        assignee_name
    ORDER BY 
        total_applications DESC
    LIMIT 1
),

MaxYearForTopAssignee AS (
    SELECT
        aa.assignee_name,
        aa.filing_year,
        aa.total_applications
    FROM 
        AssigneeApplications aa
    INNER JOIN
        TotalApplicationsPerAssignee tapa ON aa.assignee_name = tapa.assignee_name
    ORDER BY 
        aa.total_applications DESC
    LIMIT 1
)

SELECT filing_year
FROM 
    MaxYearForTopAssignee