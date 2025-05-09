WITH all_rides AS (
    SELECT
        t."pickup_datetime",
        t."pickup_longitude",
        t."pickup_latitude",
        DATE_TRUNC('hour', TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6)) AS "Pickup_Time",
        TO_DATE(TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6)) AS "Pickup_Date",
        EXTRACT(HOUR FROM TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6)) AS "Pickup_Hour"
    FROM (
        SELECT * FROM "NEW_YORK_GEO"."NEW_YORK"."TLC_YELLOW_TRIPS_2014"
        UNION ALL
        SELECT * FROM "NEW_YORK_GEO"."NEW_YORK"."TLC_YELLOW_TRIPS_2015"
    ) t
    WHERE t."pickup_longitude" BETWEEN -80 AND -70
      AND t."pickup_latitude" BETWEEN 40 AND 41
      AND t."pickup_longitude" != 0
      AND t."pickup_latitude" != 0
      AND TO_DATE(TO_TIMESTAMP_NTZ(t."pickup_datetime" / 1e6)) BETWEEN DATEADD(day, -30, '2015-01-01') AND '2015-01-01'
),
pickup_points AS (
    SELECT
        ar."Pickup_Time",
        ar."Pickup_Date",
        ar."Pickup_Hour",
        ST_POINT(ar."pickup_longitude", ar."pickup_latitude") AS "pickup_point"
    FROM all_rides ar
),
ride_zips AS (
    SELECT
        pp."Pickup_Time",
        pp."Pickup_Date",
        pp."Pickup_Hour",
        z."zip_code" AS "ZIP_Code"
    FROM pickup_points pp
    JOIN "NEW_YORK_GEO"."GEO_US_BOUNDARIES"."ZIP_CODES" z
      ON ST_CONTAINS(
           ST_GEOGFROMWKB(z."zip_code_geom"),
           pp."pickup_point"
         )
),
ride_counts AS (
    SELECT
        "Pickup_Time",
        "Pickup_Date",
        "Pickup_Hour",
        "ZIP_Code",
        COUNT(*) AS "Count_of_Rides"
    FROM ride_zips
    GROUP BY 1,2,3,4
),
metrics AS (
    SELECT
        rc.*,
        lag_counts."Count_of_Rides" AS "Hourly_Lagged_Counts",
        daily_counts."Count_of_Rides" AS "Daily_Lagged_Counts",
        weekly_counts."Count_of_Rides" AS "Weekly_Lagged_Counts",
        AVG(rc."Count_of_Rides") OVER(
            PARTITION BY rc."ZIP_Code"
            ORDER BY rc."Pickup_Time"
            ROWS BETWEEN 335 PRECEDING AND 1 PRECEDING
        ) AS "14-Day_Avg_Ride_Counts",
        STDDEV_SAMP(rc."Count_of_Rides") OVER(
            PARTITION BY rc."ZIP_Code"
            ORDER BY rc."Pickup_Time"
            ROWS BETWEEN 335 PRECEDING AND 1 PRECEDING
        ) AS "14-Day_StdDev_Ride_Counts",
        AVG(rc."Count_of_Rides") OVER(
            PARTITION BY rc."ZIP_Code"
            ORDER BY rc."Pickup_Time"
            ROWS BETWEEN 503 PRECEDING AND 1 PRECEDING
        ) AS "21-Day_Avg_Ride_Counts",
        STDDEV_SAMP(rc."Count_of_Rides") OVER(
            PARTITION BY rc."ZIP_Code"
            ORDER BY rc."Pickup_Time"
            ROWS BETWEEN 503 PRECEDING AND 1 PRECEDING
        ) AS "21-Day_StdDev_Ride_Counts"
    FROM ride_counts rc
    LEFT JOIN ride_counts lag_counts ON
        rc."ZIP_Code" = lag_counts."ZIP_Code" AND
        lag_counts."Pickup_Time" = DATEADD(hour, -1, rc."Pickup_Time")
    LEFT JOIN ride_counts daily_counts ON
        rc."ZIP_Code" = daily_counts."ZIP_Code" AND
        rc."Pickup_Hour" = daily_counts."Pickup_Hour" AND
        daily_counts."Pickup_Date" = DATEADD(day, -1, rc."Pickup_Date")
    LEFT JOIN ride_counts weekly_counts ON
        rc."ZIP_Code" = weekly_counts."ZIP_Code" AND
        rc."Pickup_Hour" = weekly_counts."Pickup_Hour" AND
        weekly_counts."Pickup_Date" = DATEADD(week, -1, rc."Pickup_Date")
)
SELECT
    TO_VARCHAR(metrics."Pickup_Time", 'YYYY-MM-DD HH24:MI:SS') AS "Pickup_Time",
    metrics."ZIP_Code",
    metrics."Count_of_Rides",
    COALESCE(metrics."Hourly_Lagged_Counts", 0) AS "Hourly_Lagged_Counts",
    COALESCE(metrics."Daily_Lagged_Counts", 0) AS "Daily_Lagged_Counts",
    COALESCE(metrics."Weekly_Lagged_Counts", 0) AS "Weekly_Lagged_Counts",
    ROUND(metrics."14-Day_Avg_Ride_Counts", 4) AS "14-Day_Avg_Ride_Counts",
    ROUND(metrics."14-Day_StdDev_Ride_Counts", 4) AS "14-Day_StdDev_Ride_Counts",
    ROUND(metrics."21-Day_Avg_Ride_Counts", 4) AS "21-Day_Avg_Ride_Counts",
    ROUND(metrics."21-Day_StdDev_Ride_Counts", 4) AS "21-Day_StdDev_Ride_Counts"
FROM metrics
WHERE metrics."Pickup_Date" = '2015-01-01'
ORDER BY metrics."Count_of_Rides" DESC NULLS LAST
LIMIT 5;