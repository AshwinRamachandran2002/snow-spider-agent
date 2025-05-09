WITH historic_hospital_nodes AS (
    SELECT
        hn."id",
        hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.HISTORY_NODES  hn,
         LATERAL FLATTEN(input => hn."all_tags") tag
    WHERE
          hn."version" = 1
      AND tag.value:"key"::string   = 'amenity'
      AND tag.value:"value"::string IN ('hospital','clinic','doctors')
      AND hn."latitude"  BETWEEN 31.1798246 AND 54.3798246
      AND hn."longitude" BETWEEN 18.4519921 AND 33.6519921
      AND NOT EXISTS (   -- node no longer present in current planet snapshot
            SELECT 1
            FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP.PLANET_NODES pn
            WHERE pn."id" = hn."id"
      )
)

SELECT
    "username",
    COUNT(DISTINCT "id") AS "missing_historic_node_count"
FROM historic_hospital_nodes
GROUP BY "username"
ORDER BY "missing_historic_node_count" DESC NULLS LAST,
         "username"
LIMIT 3;