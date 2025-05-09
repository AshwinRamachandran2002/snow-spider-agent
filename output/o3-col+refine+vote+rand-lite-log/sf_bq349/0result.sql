WITH boundaries AS (   -- all administrative multipolygon boundaries
    SELECT
        "osm_id",
        TO_GEOGRAPHY("geometry") AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES
    WHERE "feature_type" = 'multipolygons'
      AND "all_tags" ILIKE '%"boundary"%administrative%'
),
amenities AS (         -- every node tagged with “amenity”
    SELECT
        "id",
        ST_MAKEPOINT("longitude"::DOUBLE, "latitude"::DOUBLE) AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES
    WHERE "all_tags" ILIKE '%amenity%'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),
cnts AS (              -- count amenity nodes inside each boundary
    SELECT
        b."osm_id",
        COUNT(a."id") AS amenity_cnt
    FROM boundaries b
    LEFT JOIN amenities a
      ON ST_CONTAINS(b.geog, a.geog)
    GROUP BY b."osm_id"
),
med AS (               -- overall median of those counts
    SELECT MEDIAN(amenity_cnt) AS med_val
    FROM cnts
)
SELECT
    c."osm_id"      -- OSM ID of the boundary closest to the median
FROM cnts   c
CROSS JOIN med m
ORDER BY ABS(c.amenity_cnt - m.med_val),            -- closest to median
         c."osm_id"                                 -- deterministic tie-break
LIMIT 1;