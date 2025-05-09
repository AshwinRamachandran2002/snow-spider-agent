WITH ValidYears AS (
    SELECT DISTINCT CAST(SUBSTR("year", -4) AS INTEGER) AS YearNum
    FROM "Movie"
    WHERE LENGTH("year") >= 4 AND SUBSTR("year", -4) GLOB '[0-9][0-9][0-9][0-9]'
)
SELECT s.YearNum AS Start_year, COUNT(DISTINCT m."MID") AS Total_films
FROM ValidYears s
JOIN (
    SELECT "MID", CAST(SUBSTR("year", -4) AS INTEGER) AS YearNum
    FROM "Movie"
    WHERE LENGTH("year") >= 4 AND SUBSTR("year", -4) GLOB '[0-9][0-9][0-9][0-9]'
) m ON m.YearNum BETWEEN s.YearNum AND s.YearNum + 9
GROUP BY s.YearNum
ORDER BY Total_films DESC
LIMIT 1;