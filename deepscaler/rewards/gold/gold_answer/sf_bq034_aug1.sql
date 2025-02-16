-- Task: I want to know the IDs, names, and distances of weather stations from the center of Chicago (41.8319°N, 87.6847°W). Show the first 100 results.
SELECT "id", "name", ST_DISTANCE(
    TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')'),
    TO_GEOGRAPHY('POINT(-87.6847 41.8319)')
) AS "distance"
FROM "GHCN_D"."GHCN_D"."GHCND_STATIONS"
LIMIT 100;