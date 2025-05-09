SELECT
    t1."zip_code",
    ROUND(t2."total_pop", 4) AS "Population",
    ROUND(t2."income_per_capita", 4) AS "Average_Individual_Income"
FROM
    CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES.ZIP_CODES AS t1
JOIN
    CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.ZCTA5_2017_5YR AS t2
    ON t1."zip_code" = SUBSTRING(t2."geo_id", -5)
WHERE
    t1."state_name" = 'Washington'
    AND
    (ST_DISTANCE(
        ST_GEOGFROMWKB(t1."internal_point_geom"),
        ST_POINT(-122.191667, 47.685833)
    ) / 1609.34) <= 5
ORDER BY
    "Average_Individual_Income" DESC NULLS LAST;