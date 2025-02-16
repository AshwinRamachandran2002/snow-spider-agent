-- Task: For patent class A01B3, find the names of the assignees and the total number of applications filed by each assignee. List the top 5 assignees.
SELECT 
    a.value:"name" AS "assignee_name",
    COUNT(*) AS "total_applications"
FROM 
    PATENTS.PATENTS.PUBLICATIONS AS pubs,
    LATERAL FLATTEN(input => pubs."cpc") AS c,
    LATERAL FLATTEN(input => pubs."assignee_harmonized") AS a
WHERE 
    c.value:"code" LIKE 'A01B3%'
GROUP BY 
    "assignee_name"
ORDER BY
    "total_applications" DESC
LIMIT 5