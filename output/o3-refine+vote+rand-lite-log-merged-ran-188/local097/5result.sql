SELECT start_year,
       total_count
FROM (
    SELECT y AS start_year,
           (SELECT COUNT(*)
            FROM Movie AS m2
            WHERE CAST(m2.year AS INTEGER) BETWEEN y AND y + 9) AS total_count
    FROM (SELECT DISTINCT CAST(year AS INTEGER) AS y FROM Movie)
)
ORDER BY total_count DESC, start_year
LIMIT 1;