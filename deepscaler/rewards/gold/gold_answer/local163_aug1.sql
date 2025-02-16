-- Task: For each university faculty member, compute the absolute difference between their salary and the average salary for their rank. Provide the rank, first name, last name, salary, and the difference.

WITH AvgSalaries AS (
    SELECT 
        facrank AS FacRank,
        AVG(facsalary) AS AvSalary
    FROM 
        university_faculty
    GROUP BY 
        facrank
)
SELECT 
    f.facrank AS FacRank, 
    f.facfirstname AS FacFirstName, 
    f.faclastname AS FacLastName, 
    f.facsalary AS Salary, 
    ABS(f.facsalary - a.AvSalary) AS Difference
FROM 
    university_faculty f
JOIN 
    AvgSalaries a ON f.facrank = a.FacRank;