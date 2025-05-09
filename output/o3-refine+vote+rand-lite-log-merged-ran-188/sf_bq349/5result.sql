WITH boundaries AS (  -- administrative multipolygons
    SELECT DISTINCT
        COALESCE("osm_id", "osm_way_id") AS boundary_id,
        ST_GEOGFROMWKB("geometry")       AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(input => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::string = 'boundary'
      AND LOWER(tag.value:"value"::string) = 'administrative'
      AND pf."geometry" IS NOT NULL
),

amenity_pois AS (      -- nodes carrying an amenity tag
    SELECT
        ST_MAKEPOINT("longitude", "latitude") AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn,
         LATERAL FLATTEN(input => pn."all_tags") tag
    WHERE tag.value:"key"::string = 'amenity'
      AND pn."latitude"  IS NOT NULL
      AND pn."longitude" IS NOT NULL
),

boundary_poi_counts AS (  -- number of amenity POIs inside each boundary
    SELECT
        b.boundary_id,
        COUNT(*) AS poi_cnt
    FROM boundaries b
    JOIN amenity_pois p
      ON ST_CONTAINS(b.geom, p.geom)
    GROUP BY b.boundary_id
),

median_val AS (          -- median POI count
    SELECT MEDIAN(poi_cnt) AS med_cnt
    FROM boundary_poi_counts
)

-- boundary whose POI count is closest to the median
SELECT boundary_id
FROM (
    SELECT
        boundary_id,
        poi_cnt,
        ABS(poi_cnt - (SELECT med_cnt FROM median_val)) AS diff_to_median
    FROM boundary_poi_counts
)
ORDER BY diff_to_median ASC, boundary_id ASC
LIMIT 1;