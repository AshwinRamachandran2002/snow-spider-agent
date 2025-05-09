WITH track_points AS (          -- North-Atlantic hurricane positions (2020)
    SELECT
        "sid"                                                   AS sid,
        TO_NUMBER("iso_time")                                   AS iso_time,
        TO_NUMBER("latitude")                                   AS lat,
        TO_NUMBER("longitude")                                  AS lon,
        TO_GEOGRAPHY('POINT('||"longitude"||' '||"latitude"||')') AS geo
    FROM NOAA_DATA.NOAA_HURRICANES.HURRICANES
    WHERE "season" = '2020'
      AND "basin"  = 'NA'
      AND "latitude"  IS NOT NULL
      AND "longitude" IS NOT NULL
),
segments AS (                    -- distance between consecutive points
    SELECT
        tp.sid,
        ST_DISTANCE(
            tp.geo,
            TO_GEOGRAPHY(
                'POINT(' ||
                LAG(tp.lon) OVER (PARTITION BY tp.sid ORDER BY tp.iso_time) || ' ' ||
                LAG(tp.lat) OVER (PARTITION BY tp.sid ORDER BY tp.iso_time) || ')'
            )
        ) / 1000                         AS seg_km          -- metres → kilometres
    FROM track_points tp
),
storm_distance AS (              -- total distance per storm
    SELECT
        sid,
        SUM(seg_km) AS total_km
    FROM segments
    GROUP BY sid
),
second_longest AS (              -- storm with 2nd-longest path
    SELECT sid
    FROM (
        SELECT
            sid,
            total_km,
            ROW_NUMBER() OVER (ORDER BY total_km DESC NULLS LAST) AS rn
        FROM storm_distance
    )
    WHERE rn = 2
),
last_point AS (                  -- final position of that storm
    SELECT
        tp.sid,
        tp.lat,
        ROW_NUMBER() OVER (PARTITION BY tp.sid ORDER BY tp.iso_time DESC) AS rn
    FROM track_points tp
    JOIN second_longest sl ON tp.sid = sl.sid
)
SELECT lat AS "final_latitude"
FROM   last_point
WHERE  rn = 1;