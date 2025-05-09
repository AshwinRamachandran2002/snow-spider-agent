WITH boundaries AS (   -- administrative multipolygon boundaries
    SELECT DISTINCT
           pf."osm_way_id"                    AS boundary_id,
           ST_GEOGFROMWKB(pf."geometry")      AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf,
         LATERAL FLATTEN(INPUT => PARSE_JSON(pf."all_tags")) tag
    WHERE pf."feature_type" = 'multipolygons'
      AND pf."geometry" IS NOT NULL
      AND tag.value:"key"::string   = 'boundary'
      AND tag.value:"value"::string = 'administrative'
),
amenity_points AS (     -- points of interest that contain an amenity tag
    SELECT
        ST_MAKEPOINT(
            CAST(pn."longitude" AS DOUBLE),
            CAST(pn."latitude"  AS DOUBLE)
        ) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn,
         LATERAL FLATTEN(INPUT => PARSE_JSON(pn."all_tags")) tag
    WHERE pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
      AND tag.value:"key"::string = 'amenity'
),
boundary_counts AS (    -- count amenity POIs inside each boundary
    SELECT
        b.boundary_id,
        COUNT(*) AS amenity_cnt
    FROM boundaries      b
    JOIN amenity_points  p
      ON ST_CONTAINS(b.geom, p.geom)
    GROUP BY b.boundary_id
),
median_val AS (
    SELECT MEDIAN(amenity_cnt) AS med_cnt
    FROM boundary_counts
),
closest_boundary AS (
    SELECT bc.boundary_id
    FROM boundary_counts bc
    CROSS JOIN median_val mv
    ORDER BY ABS(bc.amenity_cnt - mv.med_cnt) ASC,
             bc.boundary_id
    LIMIT 1
)
SELECT boundary_id AS "OpenStreetMap_ID"
FROM closest_boundary;