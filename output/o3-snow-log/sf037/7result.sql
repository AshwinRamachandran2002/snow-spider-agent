/*--------------------------------------------------------------
  Nearest-neighbor distance between every “The Home Depot” store
  and the closest “Lowe’s Home Improvement” store
--------------------------------------------------------------*/
SELECT
       hd."HD_POI_ID"                               AS "HOME_DEPOT_POI_ID",
       lw."LOWES_POI_ID"                            AS "CLOSEST_LOWES_POI_ID",
       /* great-circle distance in miles */
       ST_DISTANCE(
            ST_MAKEPOINT(hd."HD_LONGITUDE", hd."HD_LATITUDE"),
            ST_MAKEPOINT(lw."LOWES_LONGITUDE", lw."LOWES_LATITUDE")
       ) / 1609                                    AS "DISTANCE_MILES"
FROM  (
        /* All Home Depot locations with lat/long */
        SELECT  pr."POI_ID"                         AS "HD_POI_ID",
                ua."LATITUDE"                       AS "HD_LATITUDE",
                ua."LONGITUDE"                      AS "HD_LONGITUDE"
        FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  pr
        JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    pi
                  ON pi."POI_ID" = pr."POI_ID"
        JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               ua
                  ON ua."ADDRESS_ID" = pr."ADDRESS_ID"
        WHERE  pi."POI_NAME" ILIKE '%Home%Depot%'
      ) hd
JOIN  (
        /* All Lowe’s locations with lat/long */
        SELECT  pr."POI_ID"                         AS "LOWES_POI_ID",
                ua."LATITUDE"                       AS "LOWES_LATITUDE",
                ua."LONGITUDE"                      AS "LOWES_LONGITUDE"
        FROM   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS  pr
        JOIN   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_INDEX                    pi
                  ON pi."POI_ID" = pr."POI_ID"
        JOIN   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES                               ua
                  ON ua."ADDRESS_ID" = pr."ADDRESS_ID"
        WHERE  pi."POI_NAME" ILIKE '%Lowe%Home%Improvement%'
      ) lw
/* keep only the single-nearest Lowe’s for each Home Depot */
QUALIFY ROW_NUMBER() OVER (
            PARTITION BY hd."HD_POI_ID"
            ORDER BY ST_DISTANCE(
                        ST_MAKEPOINT(hd."HD_LONGITUDE", hd."HD_LATITUDE"),
                        ST_MAKEPOINT(lw."LOWES_LONGITUDE", lw."LOWES_LATITUDE")
                     )
       ) = 1;