/*  Nearest Lowe’s for every The Home Depot store
    -------------------------------------------------
    1. Pull every Home Depot and Lowe’s POI, attach a single
       geographic coordinate per store.
    2. Cross‑join the two chains to form every possible
       HD–Lowe’s pair and compute great‑circle distance
       (ST_DISTANCE returns metres → divide by 1609 for miles).
    3. Use ROW_NUMBER so only the nearest Lowe’s record
       per Home Depot is returned.
*/
WITH  home_depot AS (
        SELECT  poi."POI_ID"                       AS "HD_POI_ID",
                addr."LATITUDE"                   AS "HD_LAT",
                addr."LONGITUDE"                  AS "HD_LON"
        FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                poi
        JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
               ON  poi."POI_ID" = rel."POI_ID"
        JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                           addr
               ON  rel."ADDRESS_ID" = addr."ADDRESS_ID"
        WHERE  poi."POI_NAME" = 'The Home Depot'
          AND  addr."LATITUDE"  IS NOT NULL
          AND  addr."LONGITUDE" IS NOT NULL
),
lowes AS (
        SELECT  poi."POI_ID"                       AS "LOWES_POI_ID",
                addr."LATITUDE"                   AS "LOWES_LAT",
                addr."LONGITUDE"                  AS "LOWES_LON"
        FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                poi
        JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS rel
               ON  poi."POI_ID" = rel."POI_ID"
        JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                           addr
               ON  rel."ADDRESS_ID" = addr."ADDRESS_ID"
        WHERE  poi."POI_NAME" = 'Lowe''s Home Improvement'
          AND  addr."LATITUDE"  IS NOT NULL
          AND  addr."LONGITUDE" IS NOT NULL
)

SELECT  hd."HD_POI_ID",
        lo."LOWES_POI_ID",
        ST_DISTANCE(
            ST_MAKEPOINT(hd."HD_LON",   hd."HD_LAT"),
            ST_MAKEPOINT(lo."LOWES_LON",lo."LOWES_LAT")
        ) / 1609      AS "DISTANCE_MILES"
FROM    home_depot  hd
CROSS JOIN lowes    lo
QUALIFY ROW_NUMBER() OVER (PARTITION BY hd."HD_POI_ID"
                           ORDER BY "DISTANCE_MILES") = 1
ORDER BY hd."HD_POI_ID";