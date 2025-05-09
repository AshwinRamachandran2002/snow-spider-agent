WITH hist_nodes AS (                 -- historical nodes carrying target amenities inside the rectangle
    SELECT
        hn."id",
        hn."username"
    FROM GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."HISTORY_NODES" hn ,
         LATERAL FLATTEN( INPUT => PARSE_JSON(hn."all_tags") ) tag
    WHERE tag.value:"key"::string = 'amenity'
      AND LOWER(tag.value:"value"::string) IN ('hospital','clinic','doctors')
      -- bounding box :  lat 31.1798246‑54.3798246 ,  lon 18.4519921‑33.6519921
      AND TO_DOUBLE(hn."latitude")  BETWEEN 31.1798246 AND 54.3798246
      AND TO_DOUBLE(hn."longitude") BETWEEN 18.4519921 AND 33.6519921
),
missing_nodes AS (                   -- those historical nodes that are absent from current planet_nodes
    SELECT DISTINCT h."id" , h."username"
    FROM hist_nodes h
    LEFT JOIN GEO_OPENSTREETMAP.GEO_OPENSTREETMAP."PLANET_NODES" pn
           ON h."id" = pn."id"
    WHERE pn."id" IS NULL
)
SELECT
    "username",
    COUNT("id") AS "missing_nodes_cnt"
FROM missing_nodes
GROUP BY "username"
ORDER BY "missing_nodes_cnt" DESC NULLS LAST , "username"
LIMIT 3;