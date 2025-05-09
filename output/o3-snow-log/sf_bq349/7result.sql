WITH admin_boundaries AS (

    /* all administrative boundaries stored as multipolygons                */
    SELECT
        COALESCE(pf."osm_id",pf."osm_way_id")          AS boundary_id ,
        TO_GEOGRAPHY(pf."geometry")                    AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES pf
         ,LATERAL FLATTEN(input => pf."all_tags") tag          /* inspect every tag  */
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:key   = 'boundary'
      AND tag.value:value = 'administrative'
      AND pf."geometry"   IS NOT NULL
),

amenity_nodes AS (

    /* every point-of-interest (POI) that carries an “amenity” tag           */
    SELECT
        pn."id"                                          AS node_id ,
        /* prefer the WKB geometry if present, otherwise build it
           from longitude / latitude                     */
        COALESCE( TO_GEOGRAPHY(pn."geometry"),
                  TO_GEOGRAPHY('POINT('||pn."longitude"||' '||pn."latitude"||')')
                )                                        AS geom
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn
         ,LATERAL FLATTEN(input => pn."all_tags") tag
    WHERE tag.value:key = 'amenity'
      AND geom IS NOT NULL
),

/* count how many amenity-POIs fall inside each administrative boundary      */
boundary_poi_counts AS (
    SELECT
        ab.boundary_id ,
        COUNT(*)                AS poi_count
    FROM admin_boundaries  ab
    JOIN amenity_nodes     an
      ON ST_CONTAINS(ab.geom,an.geom)                    /* spatial containment */
    GROUP BY ab.boundary_id
),

/* median of those counts                                                    */
median_stat AS (
    SELECT MEDIAN(poi_count) AS median_val
    FROM boundary_poi_counts
),

/* boundary whose count is closest to the median                             */
closest_boundary AS (
    SELECT
        bc.boundary_id ,
        ABS(bc.poi_count - ms.median_val) AS diff_to_median
    FROM boundary_poi_counts bc
    CROSS JOIN median_stat  ms
    ORDER BY diff_to_median ASC, bc.boundary_id   /* tie-break by id */
    LIMIT 1
)

SELECT boundary_id
FROM closest_boundary;