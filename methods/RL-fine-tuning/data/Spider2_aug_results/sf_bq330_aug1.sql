-- Task: For the first 100 overlapping block groups and zip codes in Colorado, calculate the percentage of each block group's area that overlaps with the zip code.
SELECT
    bg."geo_id",
    z."zip_code",
    (ST_AREA(ST_INTERSECTION(TO_GEOGRAPHY(z."zip_code_geom"), TO_GEOGRAPHY(bg."blockgroup_geom"))) / ST_AREA(TO_GEOGRAPHY(bg."blockgroup_geom"))) * 100 AS "percentage_overlap"
FROM "FDA"."GEO_US_BOUNDARIES"."ZIP_CODES" z
JOIN "FDA"."GEO_CENSUS_BLOCKGROUPS"."US_BLOCKGROUPS_NATIONAL" bg
    ON ST_INTERSECTS(TO_GEOGRAPHY(z."zip_code_geom"), TO_GEOGRAPHY(bg."blockgroup_geom"))
WHERE z."state_code" = 'CO' AND bg."state_fips_code" = '08'
LIMIT 100;