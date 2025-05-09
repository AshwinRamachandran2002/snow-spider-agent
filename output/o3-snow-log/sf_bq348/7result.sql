WITH hist AS (
    /*  Historical nodes that were tagged as hospital / clinic / doctors,
        lie inside the latitude-longitude rectangle
        and whose id no longer exists in current PLANET_NODES                */
    SELECT DISTINCT
           hn."id",
           hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES"  hn,
         LATERAL FLATTEN ( INPUT => hn."all_tags" ) tag
    WHERE LOWER( tag.value:"key"::string )   = 'amenity'
      AND LOWER( tag.value:"value"::string ) IN ( 'hospital'
                                                , 'clinic'
                                                , 'doctors' )
      /* rectangle:  latitude 31.1798246-54.3798246 , longitude 18.4519921-33.6519921 */
      AND hn."latitude"  BETWEEN 31.1798246  AND 54.3798246
      AND hn."longitude" BETWEEN 18.4519921 AND 33.6519921
      /* the node id is not present in current planet_nodes */
      AND NOT EXISTS (
              SELECT 1
              FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
              WHERE pn."id" = hn."id"
          )
)
SELECT
       "username",
       COUNT(*) AS "historical_node_count"
FROM hist
GROUP BY "username"
ORDER BY "historical_node_count" DESC NULLS LAST
LIMIT 3;