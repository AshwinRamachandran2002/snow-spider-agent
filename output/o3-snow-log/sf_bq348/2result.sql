WITH historical_amenity_nodes AS (           -- historical nodes with wanted amenities in the bbox
    SELECT
        hn."id"        AS id,
        hn."username"  AS username,
        hn."version"   AS version,
        CAST(hn."latitude"  AS DOUBLE)  AS lat,
        CAST(hn."longitude" AS DOUBLE)  AS lon
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES" AS hn,
         LATERAL FLATTEN( INPUT => hn."all_tags") AS tag
    WHERE tag.value:"key"::STRING   = 'amenity'
      AND tag.value:"value"::STRING IN ('hospital','clinic','doctors')
      AND CAST(hn."latitude"  AS DOUBLE)  BETWEEN 31.1798246 AND 54.3798246
      AND CAST(hn."longitude" AS DOUBLE) BETWEEN 18.4519921 AND 33.6519921
),                                           -- first (original) version of every node
first_version AS (
    SELECT
        id,
        FIRST_VALUE(username) OVER (PARTITION BY id ORDER BY version) AS username
    FROM   historical_amenity_nodes
    QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY version) = 1
),                                           -- those nodes that are missing in current planet_nodes
missing_nodes AS (
    SELECT  fv.username,
            fv.id
    FROM    first_version AS fv
            LEFT JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" AS pn
                   ON fv.id = pn."id"
    WHERE   pn."id" IS NULL
)
SELECT   username,
         COUNT(DISTINCT id) AS removed_node_count
FROM     missing_nodes
GROUP BY username
ORDER BY removed_node_count DESC NULLS LAST
LIMIT    3;