WITH amenity_hist_nodes AS (

    /* Historical nodes with the requested amenity tag
       and situated inside the given bounding box                          */
    SELECT
        HN."id"        AS node_id,
        HN."username"
    FROM  GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES"  HN,
          TABLE(FLATTEN(INPUT => HN."all_tags")) TAG
    WHERE TAG.VALUE:"key"::STRING = 'amenity'
      AND LOWER( TAG.VALUE:"value"::STRING ) IN ('hospital','clinic','doctors')
      AND TO_NUMBER(HN."latitude")  BETWEEN 31.1798246 AND 54.3798246
      AND TO_NUMBER(HN."longitude") BETWEEN 18.4519921 AND 33.6519921
),

missing_nodes AS (

    /* Nodes that existed historically but are absent from current planet_nodes */
    SELECT DISTINCT
           AHN.node_id,
           AHN."username"
    FROM   amenity_hist_nodes AHN
           LEFT JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" PN
                    ON AHN.node_id = PN."id"
    WHERE  PN."id" IS NULL
)

SELECT
       "username",
       COUNT(DISTINCT node_id) AS missing_amenity_nodes
FROM   missing_nodes
GROUP  BY "username"
ORDER  BY missing_amenity_nodes DESC NULLS LAST
LIMIT  3;