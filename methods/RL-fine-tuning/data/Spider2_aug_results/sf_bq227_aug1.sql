-- Task: Provide the top 5 minor crime categories in 2008 ranked by the total number of crimes.
SELECT
    "minor_category",
    SUM("value") AS "total_crimes"
FROM
    LONDON.LONDON_CRIME.CRIME_BY_LSOA
WHERE
    "year" = 2008
GROUP BY
    "minor_category"
ORDER BY
    "total_crimes" DESC
LIMIT 5;