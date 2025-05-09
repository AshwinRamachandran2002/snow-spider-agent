/*-----------------------------------------------------------
  Find the administrative multipolygon whose number of
  “amenity” POIs (nodes) is closest to the median count
-----------------------------------------------------------*/
WITH boundaries AS (      -- administrative multipolygon boundaries
    SELECT
        f."osm_way_id"                      AS boundary_id,
        TO_GEOGRAPHY(f."geometry")          AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES f,
         LATERAL FLATTEN (INPUT => f."all_tags") tag
    WHERE tag.value:"key"::string   = 'boundary'
      AND tag.value:"value"::string = 'administrative'
      AND f."geometry"              IS NOT NULL
      AND f."osm_way_id"            IS NOT NULL
),
poi_nodes AS (            -- nodes with an amenity tag
    SELECT
        ST_POINT(
            TO_DOUBLE(n."longitude"),
            TO_DOUBLE(n."latitude")
        )                               AS geom,
        n."id"                          AS node_id
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES n,
         LATERAL FLATTEN (INPUT => n."all_tags") tag
    WHERE tag.value:"key"::string = 'amenity'
      AND n."longitude" IS NOT NULL
      AND n."latitude"  IS NOT NULL
),
counts AS (               -- count amenity POIs per boundary
    SELECT
        b.boundary_id,
        COUNT(p.node_id)              AS poi_cnt
    FROM boundaries b
    LEFT JOIN poi_nodes p
      ON ST_INTERSECTS(b.geom, p.geom)
    GROUP BY b.boundary_id
),
median_val AS (           -- median of all counts
    SELECT MEDIAN(poi_cnt) AS med_cnt
    FROM counts
),
closest AS (              -- boundary whose count is nearest to median
    SELECT
        boundary_id AS osm_way_id
    FROM counts
    CROSS JOIN median_val
    ORDER BY ABS(poi_cnt - med_cnt) ASC,
             boundary_id            ASC
    LIMIT 1
)
SELECT osm_way_id
FROM closest;