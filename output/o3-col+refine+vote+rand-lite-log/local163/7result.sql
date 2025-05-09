WITH diffs AS (
    SELECT
        FacRank,
        FacFirstName,
        FacLastName,
        FacSalary,
        ABS(FacSalary - AVG(FacSalary) OVER (PARTITION BY FacRank)) AS diff_from_avg
    FROM university_faculty
),
mins AS (
    SELECT
        FacRank,
        MIN(diff_from_avg) AS min_diff
    FROM diffs
    GROUP BY FacRank
)
SELECT
    d.FacRank      AS rank,
    d.FacFirstName AS first_name,
    d.FacLastName  AS last_name,
    d.FacSalary    AS salary
FROM diffs d
JOIN mins m
  ON d.FacRank = m.FacRank
 AND d.diff_from_avg = m.min_diff
ORDER BY d.FacRank, d.FacLastName, d.FacFirstName;