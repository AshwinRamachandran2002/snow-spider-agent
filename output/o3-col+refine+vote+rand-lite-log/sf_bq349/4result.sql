/* 1.  Pick all multipolygon features that are tagged      */
/*     boundary=administrative (i.e. admin boundaries).    */
/* 2.  Pick all nodes that possess an 'amenity' tag.        */
/* 3.  Count, for every boundary, how many amenity-nodes    */
/*     fall inside the polygon (ST_CONTAINS).              */
/* 4.  Compute the median of those counts.                  */
/* 5.  Return the OSM id whose count is closest to median.  */
WITH administrative_boundaries AS (
    SELECT
        pf."osm_id",
        TO_GEOGRAPHY(pf."geometry")             AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_FEATURES  pf ,
         LATERAL FLATTEN (INPUT => pf."all_tags") tag
    WHERE pf."feature_type" = 'multipolygons'
      AND tag.value:"key"::STRING   = 'boundary'
      AND tag.value:"value"::STRING = 'administrative'
      AND pf."geometry" IS NOT NULL
),
amenity_nodes AS (
    SELECT
        ST_MAKEPOINT("longitude"::DOUBLE, "latitude"::DOUBLE) AS geog
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES     pn ,
         LATERAL FLATTEN (INPUT => pn."all_tags") tag
    WHERE tag.value:"key"::STRING = 'amenity'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),
boundary_poi_counts AS (
    SELECT
        ab."osm_id",
        COUNT(*) AS poi_cnt
    FROM administrative_boundaries ab
    JOIN amenity_nodes           an
      ON ST_CONTAINS(ab.geog , an.geog)
    GROUP BY ab."osm_id"
),
median_val AS (
    SELECT MEDIAN(poi_cnt) AS median_cnt
    FROM boundary_poi_counts
)
SELECT
    bpc."osm_id"
FROM boundary_poi_counts bpc
CROSS JOIN median_val mv
QUALIFY ROW_NUMBER() OVER (
            ORDER BY ABS(bpc.poi_cnt - mv.median_cnt),
                     bpc."osm_id"
        ) = 1;