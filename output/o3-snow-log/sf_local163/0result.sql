WITH rank_avg AS (
    -- average salary for every faculty rank
    SELECT 
        "FacRank",
        AVG("FacSalary") AS avg_salary
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY
    GROUP BY "FacRank"
),
rank_diff AS (
    -- difference between each faculty member's salary and the average for their rank
    SELECT
        f."FacRank",
        f."FacFirstName",
        f."FacLastName",
        f."FacSalary",
        ABS(f."FacSalary" - a.avg_salary) AS diff_to_avg
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.UNIVERSITY_FACULTY AS f
    JOIN rank_avg AS a
      ON f."FacRank" = a."FacRank"
)
-- pick the faculty member(s) with the minimum difference to the average salary in each rank
SELECT
    "FacRank"       AS rank,
    "FacFirstName"  AS first_name,
    "FacLastName"   AS last_name,
    "FacSalary"     AS salary
FROM rank_diff
QUALIFY diff_to_avg = MIN(diff_to_avg) OVER (PARTITION BY "FacRank")
ORDER BY "FacRank", "FacSalary";