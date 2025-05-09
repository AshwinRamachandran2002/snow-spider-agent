WITH administrative_boundaries AS (

    /* --- multipolygon features that have the tag boundary = administrative --- */
    SELECT DISTINCT
           COALESCE(pf."osm_id" , pf."osm_way_id")                AS boundary_osm_id ,
           TO_GEOGRAPHY(pf."geometry")                            AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf ,
         LATERAL FLATTEN ( INPUT => pf."all_tags" ) tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key" ::STRING   = 'boundary'
      AND tag.value:"value"::STRING  = 'administrative'

), amenity_pois AS (

    /* --- point features (nodes) that carry an amenity tag --- */
    SELECT
           ST_MAKEPOINT("longitude"::DOUBLE , "latitude"::DOUBLE) AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn ,
         LATERAL FLATTEN ( INPUT => pn."all_tags" ) tag
    WHERE pn."longitude" IS NOT NULL
      AND pn."latitude"  IS NOT NULL
      AND tag.value:"key"::STRING = 'amenity'

), amenity_counts AS (

    /* --- count of amenity POIs inside each administrative boundary --- */
    SELECT   b.boundary_osm_id ,
             COUNT(*) AS amenity_cnt
    FROM     administrative_boundaries b
    JOIN     amenity_pois            n
         ON  ST_CONTAINS(b.geom , n.geom)
    GROUP BY b.boundary_osm_id

), median_val AS (

    SELECT MEDIAN(amenity_cnt) AS med_cnt
    FROM   amenity_counts
)

SELECT  boundary_osm_id
FROM   (
        SELECT  ac.boundary_osm_id ,
                ac.amenity_cnt ,
                ABS(ac.amenity_cnt - mv.med_cnt) AS diff_from_median
        FROM    amenity_counts ac
        CROSS JOIN median_val mv
       )
ORDER BY diff_from_median ASC ,
         boundary_osm_id        -- deterministic tie‑break
LIMIT 1;