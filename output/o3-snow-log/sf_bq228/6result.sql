SELECT
    "major_category",
    SUM("value") AS "num_incidents"
FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
WHERE "borough" = 'Barking and Dagenham'
GROUP BY "major_category"
ORDER BY "num_incidents" DESC NULLS LAST
LIMIT 3;