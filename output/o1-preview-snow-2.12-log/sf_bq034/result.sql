SELECT "id", "name"
FROM "GHCN_D"."GHCN_D"."GHCND_STATIONS"
WHERE ST_DISTANCE(
    TO_GEOGRAPHY('POINT(' || "longitude" || ' ' || "latitude" || ')'),
    TO_GEOGRAPHY('POINT(-87.6847 41.8319)')
) <= 50000;