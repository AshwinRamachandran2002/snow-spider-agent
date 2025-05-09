WITH avg_salary AS (
    SELECT
        "FacRank",
        AVG("FacSalary") AS avg_rank_salary
    FROM "university_faculty"
    WHERE "FacSalary" IS NOT NULL
    GROUP BY "FacRank"
),
diffs AS (
    SELECT
        uf."FacRank",
        uf."FacFirstName",
        uf."FacLastName",
        uf."FacSalary",
        ABS(uf."FacSalary" - a.avg_rank_salary) AS diff_from_avg
    FROM "university_faculty" AS uf
    JOIN avg_salary AS a
      ON uf."FacRank" = a."FacRank"
),
ranked AS (
    SELECT
        d.*,
        RANK() OVER (PARTITION BY d."FacRank" ORDER BY d.diff_from_avg) AS rnk
    FROM diffs AS d
)
SELECT
    "FacRank"      AS rank,
    "FacFirstName" AS first_name,
    "FacLastName"  AS last_name,
    "FacSalary"    AS salary
FROM ranked
WHERE rnk = 1
ORDER BY rank, first_name, last_name;