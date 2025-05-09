SELECT
    "major_category",
    SUM("value") AS "incidents"
FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
WHERE "borough" = 'Barking and Dagenham'
GROUP BY "major_category"
ORDER BY "incidents" DESC NULLS LAST
LIMIT 3;