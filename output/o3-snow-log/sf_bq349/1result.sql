WITH administrative_boundaries AS (   -- all admin boundaries stored as multipolygons
    SELECT
        COALESCE("osm_id","osm_way_id")            AS boundary_id,
        TO_GEOMETRY("geometry")                    AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  pf,
         LATERAL FLATTEN(INPUT => pf."all_tags")   tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::string   = 'boundary'
      AND tag.value:"value"::string = 'administrative'
      AND pf."geometry" IS NOT NULL
),    

amenity_nodes AS (                              -- all nodes having an «amenity» tag
    SELECT
        "id"                                     AS node_id,
        TO_GEOMETRY("geometry")                  AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn,
         LATERAL FLATTEN(INPUT => pn."all_tags") tag
    WHERE tag.value:"key"::string = 'amenity'
      AND pn."geometry" IS NOT NULL
),    

boundary_counts AS (                            -- POI count per boundary
    SELECT
        b.boundary_id,
        COUNT(*)                                AS cnt
    FROM administrative_boundaries b
    JOIN amenity_nodes        n
          ON ST_CONTAINS(b.geom , n.geom)
    GROUP BY b.boundary_id
),    

median_cte AS (                                 -- median of all those counts
    SELECT MEDIAN(cnt) AS med
    FROM   boundary_counts
)

SELECT boundary_id                              -- the OSM id closest to the median
FROM   boundary_counts ,
       median_cte
ORDER  BY ABS(cnt - med) ASC , boundary_id ASC
LIMIT  1;