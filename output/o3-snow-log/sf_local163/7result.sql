SELECT 
    "FacRank"                               AS "Rank",
    "FacFirstName"                          AS "FirstName",
    "FacLastName"                           AS "LastName",
    "FacSalary"                             AS "Salary"
FROM (
    SELECT 
        "FacRank",
        "FacFirstName",
        "FacLastName",
        "FacSalary",
        ABS("FacSalary" - AVG("FacSalary") OVER (PARTITION BY "FacRank")) AS diff_to_avg
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    WHERE "FacSalary" IS NOT NULL
)
QUALIFY diff_to_avg = MIN(diff_to_avg) OVER (PARTITION BY "FacRank")
ORDER BY "FacRank", "FacLastName", "FacFirstName";