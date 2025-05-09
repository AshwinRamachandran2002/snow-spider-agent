SELECT
    "major_category"             AS MAJOR_CATEGORY,
    SUM(COALESCE("value", 0))    AS INCIDENTS
FROM
    LONDON.LONDON_CRIME."CRIME_BY_LSOA"
WHERE
    "borough" = 'Barking and Dagenham'
GROUP BY
    "major_category"
ORDER BY
    INCIDENTS DESC NULLS LAST
LIMIT 3;