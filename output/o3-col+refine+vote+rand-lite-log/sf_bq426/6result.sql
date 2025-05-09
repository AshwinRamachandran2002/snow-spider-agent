WITH zip_geom AS (
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE "zip_code" = '10019'
),
zip_station_names AS (   -- every Citi Bike station that lies inside ZIP 10019
    SELECT DISTINCT s."name"
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_STATIONS"  s
    CROSS JOIN zip_geom z
    WHERE ST_WITHIN(
            TO_GEOGRAPHY( ST_MAKEPOINT(s."longitude", s."latitude") ),
            z.geom
          )
),
daily_user_dates AS (    -- each day × user-type that recorded ≥1 trip fully inside ZIP 10019
    SELECT
        DATE( TO_TIMESTAMP(t."starttime" / 1000000) ) AS trip_date,
        t."usertype"
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE DATE_TRUNC('year', TO_TIMESTAMP(t."starttime" / 1000000)) = '2018-01-01'
      AND t."start_station_name" IN (SELECT "name" FROM zip_station_names)
      AND t."end_station_name"   IN (SELECT "name" FROM zip_station_names)
    GROUP BY 1,2
),
central_park_weather AS (
    SELECT 
        TO_DATE('2018-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS wx_date,
        "temp",                      -- °F
        "prcp",                      -- inches
        "wdsp"::FLOAT AS wdsp_knots  -- knots
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018"
    WHERE "wban" = '94728'          -- New York Central Park station
)
SELECT
    d."usertype",
    AVG(w."temp")       AS "avg_temp_f",
    AVG(w."prcp")       AS "avg_prcp_in",
    AVG(w.wdsp_knots)   AS "avg_wind_knots"
FROM daily_user_dates        d
JOIN central_park_weather    w
  ON w.wx_date = d.trip_date
GROUP BY d."usertype"
ORDER BY "avg_temp_f" DESC NULLS LAST
LIMIT 1;