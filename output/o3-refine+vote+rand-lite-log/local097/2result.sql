SELECT 
    y.start_year,
    COUNT(m.MID) AS total_count
FROM (
        SELECT DISTINCT CAST(year AS INTEGER) AS start_year
        FROM Movie
     ) AS y
JOIN Movie AS m
     ON CAST(m.year AS INTEGER) BETWEEN y.start_year AND y.start_year + 9
GROUP BY y.start_year
ORDER BY total_count DESC, y.start_year ASC
LIMIT 1;