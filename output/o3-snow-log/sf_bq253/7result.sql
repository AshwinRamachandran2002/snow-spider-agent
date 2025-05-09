/*---------------------------------------------------------------
   Goal:  Return the name of the (named-but-no-wikidata) relation
          that covers the largest number of PLANET_FEATURES
          lying inside the area of the multipolygon that is
          tagged with wikidata = Q1095.  At least one of those
          covered features must itself have a wikidata tag.
 ----------------------------------------------------------------*/

WITH q1095 AS (          /* take the LARGEST polygon tagged Q1095 */
    SELECT ST_GEOGFROMWKB("geometry") AS geom
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES"
    WHERE  "geometry" IS NOT NULL
      AND  "feature_type" = 'multipolygons'
      AND  "all_tags" ILIKE '%"wikidata"%Q1095%'
    ORDER  BY ST_AREA( ST_GEOGFROMWKB("geometry") ) DESC
    LIMIT  1
),

/* candidate relations: have a name, NO wikidata, intersect Q1095 */
candidate_relations AS (
    SELECT r."id",
           ST_GEOGFROMWKB(r."geometry") AS geom,
           r."all_tags"
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_RELATIONS" r,
           q1095
    WHERE  r."geometry" IS NOT NULL
      AND  ST_INTERSECTS( ST_GEOGFROMWKB(r."geometry"), q1095.geom )
      AND  r."all_tags" ILIKE '%"name"%'
      AND  r."all_tags" NOT ILIKE '%"wikidata"%'
),

/* extract the relation’s name */
relation_names AS (
    SELECT cr."id",
           tag.value:"value"::STRING AS rel_name,
           cr.geom
    FROM   candidate_relations cr,
           LATERAL FLATTEN(INPUT => PARSE_JSON(cr."all_tags")) tag
    WHERE  tag.value:"key"::STRING = 'name'
),

/* every PLANET_FEATURE located inside the Q1095 polygon */
features_in_q1095 AS (
    SELECT ST_GEOGFROMWKB(f."geometry") AS geom,
           f."all_tags"
    FROM   GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_FEATURES" f,
           q1095
    WHERE  f."geometry" IS NOT NULL
      AND  ST_INTERSECTS( ST_GEOGFROMWKB(f."geometry"), q1095.geom )
),

/* count how many such features each relation encloses            */
relation_stats AS (
    SELECT rn.rel_name                                 AS relation_name,
           COUNT(*)                                    AS feature_cnt,
           SUM( CASE WHEN fi."all_tags" ILIKE '%"wikidata"%' THEN 1 ELSE 0 END )
                                                       AS wd_feature_cnt
    FROM   relation_names   rn
    JOIN   features_in_q1095 fi
           ON ST_INTERSECTS( fi.geom , rn.geom )
    GROUP  BY rn.rel_name
    HAVING wd_feature_cnt > 0          /* must include ≥1 wikidata feature */
)

/* final answer                                                    */
SELECT relation_name
FROM   relation_stats
ORDER  BY feature_cnt DESC NULLS LAST
LIMIT  1;