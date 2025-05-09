WITH cities AS (
    SELECT
        "geolocation_city" AS "city",
        "geolocation_state" AS "state",
        AVG("geolocation_lat") AS "lat",
        AVG("geolocation_lng") AS "lng"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_GEOLOCATION"
    WHERE
        "geolocation_lat" BETWEEN -35 AND 5    -- Valid latitude range for Brazil
        AND "geolocation_lng" BETWEEN -75 AND -32   -- Valid longitude range for Brazil
        AND "geolocation_lat" IS NOT NULL
        AND "geolocation_lng" IS NOT NULL
    GROUP BY "geolocation_city", "geolocation_state"
),
city_pairs AS (
    SELECT
        c1."city" AS "City1",
        c2."city" AS "City2",
        ACOS(LEAST(1, GREATEST(-1,
            COS(RADIANS(c1."lat")) * COS(RADIANS(c2."lat")) *
            COS(RADIANS(c2."lng") - RADIANS(c1."lng")) +
            SIN(RADIANS(c1."lat")) * SIN(RADIANS(c2."lat"))
        ))) * 6371 AS "Distance_km"
    FROM cities c1
    JOIN cities c2 ON c1."state" = c2."state" AND c1."city" <> c2."city"
),
nearest_neighbors AS (
    SELECT
        cp."City1",
        cp."City2",
        cp."Distance_km",
        ROW_NUMBER() OVER (PARTITION BY cp."City1" ORDER BY cp."Distance_km" ASC) AS rn
    FROM city_pairs cp
    WHERE cp."Distance_km" IS NOT NULL
)
SELECT
    nn."City1",
    nn."City2",
    ROUND(nn."Distance_km", 4) AS "Distance_km"
FROM nearest_neighbors nn
WHERE nn.rn = 1
ORDER BY nn."Distance_km" DESC NULLS LAST
LIMIT 1;