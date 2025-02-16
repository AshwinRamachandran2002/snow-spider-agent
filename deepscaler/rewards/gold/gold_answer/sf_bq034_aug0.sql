-- Task: Retrieve the IDs and names of weather stations from the "GHCND_STATIONS" table whose geographical locations are within a 50-kilometer straight-line distance (measured using ST_DISTANCE in meters) from the center of Chicago (latitude 41.8319°, longitude -87.6847°).
SELECT "id", "name"
FROM "GHCN_D"."GHCN_D"."GHCND_STATIONS"
WHERE ST_DISTANCE(
    TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')'),
    TO_GEOGRAPHY('POINT(-87.6847 41.8319)')
) <= 50000;