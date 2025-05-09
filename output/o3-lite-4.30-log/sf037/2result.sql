/* ==============================================================
   Shortest straight‑line distance (miles) from each “Home Depot”
   store to its nearest “Lowe’s Home Improvement” store
   ============================================================= */

WITH
/* ---------- Home Depot store coordinates ---------- */
hd AS (
    SELECT
        idx."POI_ID"        AS "HD_POI_ID",
        addr."LATITUDE"     AS "HD_LAT",
        addr."LONGITUDE"    AS "HD_LON"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  idx
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
           ON idx."POI_ID" = rel."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              addr
           ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE  idx."POI_NAME" ILIKE '%Home%Depot%'        -- Home Depot (incl. “The Home Depot”)
      AND  addr."LATITUDE"  IS NOT NULL
      AND  addr."LONGITUDE" IS NOT NULL
),

/* ---------- Lowe’s store coordinates ---------- */
lw AS (
    SELECT
        idx."POI_ID"        AS "LOWES_POI_ID",
        addr."LATITUDE"     AS "LOWES_LAT",
        addr."LONGITUDE"    AS "LOWES_LON"
    FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                  idx
    JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
           ON idx."POI_ID" = rel."POI_ID"
    JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                              addr
           ON rel."ADDRESS_ID" = addr."ADDRESS_ID"
    WHERE  idx."POI_NAME" ILIKE '%Lowe%Home%Improvement%'  -- Lowe’s Home Improvement
      AND  addr."LATITUDE"  IS NOT NULL
      AND  addr."LONGITUDE" IS NOT NULL
)

/* ---------- Compute nearest Lowe’s for every Home Depot ---------- */
SELECT
    hd."HD_POI_ID"                                                       AS home_depot_poi_id,
    ST_ASWKT(ST_MAKEPOINT(hd."HD_LON", hd."HD_LAT"))                     AS home_depot_coordinates,
    lw."LOWES_POI_ID"                                                    AS nearest_lowes_poi_id,
    ST_ASWKT(ST_MAKEPOINT(lw."LOWES_LON", lw."LOWES_LAT"))               AS lowes_coordinates,
    ROUND(
        ST_DISTANCE(
            ST_MAKEPOINT(hd."HD_LON", hd."HD_LAT"),
            ST_MAKEPOINT(lw."LOWES_LON", lw."LOWES_LAT")
        ) / 1609,                                                        -- meters → miles
        4
    )                                                                    AS straight_line_distance_miles
FROM   hd
CROSS  JOIN lw
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(
                        ST_MAKEPOINT(hd."HD_LON", hd."HD_LAT"),
                        ST_MAKEPOINT(lw."LOWES_LON", lw."LOWES_LAT")
                     )
        ) = 1
ORDER BY home_depot_poi_id;