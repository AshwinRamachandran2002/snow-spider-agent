WITH boundaries AS (  -- all administrative boundaries stored as multipolygons
    SELECT
        COALESCE("osm_id","osm_way_id")                 AS boundary_id,
        TO_GEOGRAPHY("geometry")                        AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES ,
         LATERAL FLATTEN(input => "all_tags") tag
    WHERE "feature_type" = 'multipolygons'
      AND tag.value:"key"::string = 'boundary'
      AND LOWER(tag.value:"value"::string) = 'administrative'
      AND "geometry" IS NOT NULL
), poi AS (          -- all point‑features that carry an amenity tag
    SELECT
        "id"                                            AS node_id,
        ST_MAKEPOINT("longitude"::double , "latitude"::double)  AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES ,
         LATERAL FLATTEN(input => "all_tags") tag
    WHERE tag.value:"key"::string = 'amenity'
      AND "longitude" IS NOT NULL
      AND "latitude"  IS NOT NULL
), boundary_poi_counts AS (      -- count amenity POIs inside every boundary
    SELECT
        b.boundary_id,
        COUNT(*)                                           AS poi_cnt
    FROM boundaries b
    JOIN poi        p
      ON ST_CONTAINS(b.geom , p.geom)
    GROUP BY b.boundary_id
), med AS (                       -- median of those counts
    SELECT MEDIAN(poi_cnt) AS med_cnt
    FROM boundary_poi_counts
), ranked AS (                    -- distance to median
    SELECT
        c.boundary_id,
        c.poi_cnt,
        m.med_cnt,
        ABS(c.poi_cnt - m.med_cnt) AS diff_to_median
    FROM boundary_poi_counts c
    CROSS JOIN med m
)
SELECT boundary_id                -- administrative boundary whose amenity‑POI
FROM ranked                       -- count is closest to the median
ORDER BY diff_to_median ASC,
         boundary_id ASC          -- tie‑breaker: smaller OSM id
LIMIT 1;