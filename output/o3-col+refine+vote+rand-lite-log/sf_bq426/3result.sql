WITH zip_polygon          AS (           -- geometry for ZIP 10019
    SELECT TO_GEOGRAPHY(z."zip_code_geom") AS "geom"
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" z
    WHERE  z."zip_code" = '10019'
),

zip_station_names   AS (           -- station names that fall inside ZIP 10019
    SELECT DISTINCT s."name"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_STATIONS" s
    CROSS JOIN zip_polygon zp
    WHERE  ST_WITHIN(
              ST_MAKEPOINT(s."longitude", s."latitude"),
              zp."geom"
           )
),

zip_trips_2018      AS (           -- 2018 trips whose START and END stations are both in ZIP 10019
    SELECT
        t."usertype",
        TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1e6)) AS "trip_date"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE  TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1e6))
              BETWEEN '2018-01-01' AND '2018-12-31'
      AND  t."start_station_name" IN (SELECT * FROM zip_station_names)
      AND  t."end_station_name"   IN (SELECT * FROM zip_station_names)
),

central_park_wx_2018 AS (          -- daily weather for Central Park (WBAN 94728)
    SELECT
        DATE_FROM_PARTS(g."year"::INT, g."mo"::INT, g."da"::INT)                 AS "wx_date",
        g."temp"                                                                AS "temp_F",
        NULLIF(g."prcp", 99.99)                                                 AS "prcp_in",
        NULLIF(g."wdsp", '999.9')::FLOAT                                        AS "wind_knots"
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018" g
    WHERE  g."wban" = '94728'
),

per_usertype_weather AS (          -- join trips with weather and compute averages
    SELECT
        zt."usertype",
        AVG(wx."temp_F")     AS "avg_temp_F",
        AVG(wx."prcp_in")    AS "avg_prcp_in",
        AVG(wx."wind_knots") AS "avg_wind_knots"
    FROM   zip_trips_2018 zt
    JOIN   central_park_wx_2018 wx
           ON zt."trip_date" = wx."wx_date"
    GROUP  BY zt."usertype"
)

SELECT *
FROM   per_usertype_weather
ORDER  BY "avg_temp_F" DESC NULLS LAST
LIMIT  1;