WITH boundaries AS (               -- every administrative-boundary multipolygon
    SELECT
        COALESCE(pf."osm_way_id", pf."osm_id")              AS "boundary_id",
        ST_CENTROID(TO_GEOGRAPHY(pf."geometry"))            AS "centroid_geo"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" pf,
         LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"   = 'boundary'
      AND tag.value:"value" = 'administrative'
      AND pf."geometry"     IS NOT NULL
),
amenities AS (                     -- every node that carries an amenity tag
    SELECT
        ST_MAKEPOINT(pn."longitude"::FLOAT , pn."latitude"::FLOAT) AS "poi_geo"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn,
         LATERAL FLATTEN (INPUT => pn."all_tags") tag
    WHERE tag.value:"key" = 'amenity'
      AND pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
),
counts AS (                        -- amenity count within 50 km of each boundary
    SELECT
        b."boundary_id",
        COUNT(*) AS "amenity_cnt"
    FROM boundaries b
    JOIN amenities a
      ON ST_DWITHIN(b."centroid_geo", a."poi_geo", 50000)   -- 50 000 m radius
    GROUP BY b."boundary_id"
),
stats AS ( SELECT MEDIAN("amenity_cnt") AS "median_cnt" FROM counts )
SELECT
    c."boundary_id"                       -- ← OpenStreetMap ID requested
FROM counts c
CROSS JOIN stats s
ORDER BY ABS(c."amenity_cnt" - s."median_cnt") ASC,   -- closest to median
         c."amenity_cnt" ASC                         -- tie-breaker (smaller)
LIMIT 1;