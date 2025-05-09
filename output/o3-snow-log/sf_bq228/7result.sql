SELECT
    "major_category",
    SUM("value") AS "incident_count"
FROM LONDON.LONDON_CRIME.CRIME_BY_LSOA
WHERE "borough" = 'Barking and Dagenham'
GROUP BY "major_category"
ORDER BY "incident_count" DESC NULLS LAST
FETCH 3 ROWS ONLY;