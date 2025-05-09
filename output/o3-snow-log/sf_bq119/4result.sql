/* ---------------------------------------------------------------
   1)  Get all 2020 North-Atlantic (“NA”) main-track hurricane fixes
   2)  Compute segment distances (km) between successive fixes
   3)  Sum per storm, rank by total distance, pick the 3rd longest
   4)  Return that storm’s track with cumulative distance & wind
---------------------------------------------------------------- */
WITH atl2020 AS (         -- 2020 NA main-track positions
    SELECT
        "sid"        AS SID,
        "name"       AS NAME,
        "iso_time"   AS ISO_TIME,
        "latitude"   AS LAT,
        "longitude"  AS LON,
        "usa_wind"   AS WIND
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'
      AND "track_type" = 'main'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),
track_with_dist AS (      -- add great-circle distance between fixes
    SELECT
        SID,
        NAME,
        ISO_TIME,
        LAT,
        LON,
        WIND,
        CASE
            WHEN LAG(LAT) OVER (PARTITION BY SID ORDER BY ISO_TIME) IS NULL
                 THEN 0
            ELSE 6371 * 2 * ASIN(
                     SQRT(
                         POWER(
                             SIN(
                                 (RADIANS(LAT) -
                                  RADIANS(LAG(LAT) OVER (PARTITION BY SID ORDER BY ISO_TIME)))
                                 / 2
                             ),2)
                         +
                         COS(RADIANS(LAG(LAT) OVER (PARTITION BY SID ORDER BY ISO_TIME)))
                         * COS(RADIANS(LAT))
                         * POWER(
                               SIN(
                                   (RADIANS(LON) -
                                    RADIANS(LAG(LON) OVER (PARTITION BY SID ORDER BY ISO_TIME)))
                                   / 2
                               ),2)
                     )
                 )
        END AS SEG_KM
    FROM atl2020
),
storm_totals AS (         -- total travel distance per storm
    SELECT
        SID,
        NAME,
        SUM(SEG_KM) AS TOTAL_KM
    FROM track_with_dist
    GROUP BY SID, NAME
),
ranked AS (               -- rank storms by travel distance
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY TOTAL_KM DESC) AS RNK
    FROM storm_totals
),
third_storm AS (          -- the third-longest storm
    SELECT SID
    FROM ranked
    WHERE RNK = 3
),
final AS (                -- cumulative distance along the track
    SELECT
        t.SID,
        t.NAME,
        TO_TIMESTAMP_NTZ(t.ISO_TIME/1000000) AS OBS_TIME,
        t.LAT,
        t.LON,
        SUM(t.SEG_KM) OVER (PARTITION BY t.SID ORDER BY t.ISO_TIME
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS CUM_KM,
        t.WIND
    FROM track_with_dist t
    JOIN third_storm s
      ON t.SID = s.SID
)
SELECT
    SID                     AS "Storm_ID",
    NAME                    AS "Storm_Name",
    OBS_TIME                AS "Observation_Time",
    LAT                     AS "Latitude",
    LON                     AS "Longitude",
    ROUND(CUM_KM,2)         AS "Cumulative_Distance_km",
    WIND                    AS "Max_Sustained_Wind_knots"
FROM final
ORDER BY OBS_TIME;