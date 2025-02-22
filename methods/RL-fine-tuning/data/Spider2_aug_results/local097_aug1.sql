-- Task: Extract all unique valid movie release years from the data.

SELECT DISTINCT CAST(SUBSTR("year", -4) AS INTEGER) AS YearNum
FROM "Movie"
WHERE LENGTH("year") >= 4 AND SUBSTR("year", -4) GLOB '[0-9][0-9][0-9][0-9]'
ORDER BY YearNum;