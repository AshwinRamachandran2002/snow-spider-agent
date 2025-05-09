SELECT
    y.start_year,
    COUNT(m2.MID) AS total_films
FROM (
    SELECT DISTINCT CAST(year AS INT) AS start_year
    FROM Movie
) AS y
JOIN Movie AS m2
    ON CAST(m2.year AS INT) BETWEEN y.start_year AND y.start_year + 9
GROUP BY y.start_year
ORDER BY total_films DESC, start_year ASC
LIMIT 1;