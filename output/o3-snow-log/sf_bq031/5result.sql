/*--------------------------------------------------------------------
  Rochester (USAF 725290 – WBAN 14768)
  Daily weather   :  1 Jan – 31 Mar 2019
  • temp_c      – mean temperature °C
  • prcp_cm     – precipitation cm   (99.99 = missing → NULL)
  • wind_ms     – mean wind-speed m s-¹
  • ma8_*       – 8-day moving averages (current day + 7 prior)
  • *_diff_lagN – difference with the MA from N days ago
  Rounded to 1 decimal; results start 9 Jan 2019 (first day MA is
  fully defined) and are ordered chronologically.
--------------------------------------------------------------------*/
WITH raw AS (      --------------------------------------------------
    SELECT
        /* build real date from separate Y-M-D fields */
        TO_DATE(
            CONCAT("year" ,'-',LPAD("mo",2,'0'),'-',LPAD("da",2,'0'))
        )                                              AS "date",

        /* convert / round daily values -----------------------------*/
        ROUND( ( "temp" - 32 ) * 5/9 , 1)                               AS "temp_c",
        ROUND( CASE WHEN "prcp" < 99.99 THEN "prcp"*2.54 END , 1)       AS "prcp_cm",
        ROUND( ( "wdsp"::FLOAT ) * 0.514444 , 1)                        AS "wind_ms"
    FROM NOAA_DATA.NOAA_GSOD."GSOD2019"
    WHERE "stn"  = '725290'                 -- Rochester, NY station
      AND "wban" = '14768'
      AND TO_DATE(
            CONCAT("year" ,'-',LPAD("mo",2,'0'),'-',LPAD("da",2,'0'))
          ) BETWEEN '2019-01-01' AND '2019-03-31'
),
ma AS (           ----------------------------------------------------
    SELECT
        "date",
        "temp_c",
        "prcp_cm",
        "wind_ms",

        /* 8-day (current + 7 previous) moving averages */
        ROUND(
            AVG("temp_c")  OVER (ORDER BY "date"
                                 ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1
        ) AS "ma8_temp",

        ROUND(
            AVG("prcp_cm") OVER (ORDER BY "date"
                                 ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1
        ) AS "ma8_prcp",

        ROUND(
            AVG("wind_ms") OVER (ORDER BY "date"
                                 ROWS BETWEEN 7 PRECEDING AND CURRENT ROW), 1
        ) AS "ma8_wind"
    FROM raw
)
SELECT
    /* daily values & 8-day moving averages -------------------------*/
    "date",
    "temp_c",
    "prcp_cm",
    "wind_ms",
    "ma8_temp",
    "ma8_prcp",
    "ma8_wind",

    /* lag-difference columns – temperature -------------------------*/
    ROUND("ma8_temp" - LAG("ma8_temp",1) OVER (ORDER BY "date"), 1) AS "temp_diff_lag1",
    ROUND("ma8_temp" - LAG("ma8_temp",2) OVER (ORDER BY "date"), 1) AS "temp_diff_lag2",
    ROUND("ma8_temp" - LAG("ma8_temp",3) OVER (ORDER BY "date"), 1) AS "temp_diff_lag3",
    ROUND("ma8_temp" - LAG("ma8_temp",4) OVER (ORDER BY "date"), 1) AS "temp_diff_lag4",
    ROUND("ma8_temp" - LAG("ma8_temp",5) OVER (ORDER BY "date"), 1) AS "temp_diff_lag5",
    ROUND("ma8_temp" - LAG("ma8_temp",6) OVER (ORDER BY "date"), 1) AS "temp_diff_lag6",
    ROUND("ma8_temp" - LAG("ma8_temp",7) OVER (ORDER BY "date"), 1) AS "temp_diff_lag7",
    ROUND("ma8_temp" - LAG("ma8_temp",8) OVER (ORDER BY "date"), 1) AS "temp_diff_lag8",

    /* lag-difference columns – precipitation -----------------------*/
    ROUND("ma8_prcp" - LAG("ma8_prcp",1) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag1",
    ROUND("ma8_prcp" - LAG("ma8_prcp",2) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag2",
    ROUND("ma8_prcp" - LAG("ma8_prcp",3) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag3",
    ROUND("ma8_prcp" - LAG("ma8_prcp",4) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag4",
    ROUND("ma8_prcp" - LAG("ma8_prcp",5) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag5",
    ROUND("ma8_prcp" - LAG("ma8_prcp",6) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag6",
    ROUND("ma8_prcp" - LAG("ma8_prcp",7) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag7",
    ROUND("ma8_prcp" - LAG("ma8_prcp",8) OVER (ORDER BY "date"), 1) AS "prcp_diff_lag8",

    /* lag-difference columns – wind speed ---------------------------*/
    ROUND("ma8_wind" - LAG("ma8_wind",1) OVER (ORDER BY "date"), 1) AS "wind_diff_lag1",
    ROUND("ma8_wind" - LAG("ma8_wind",2) OVER (ORDER BY "date"), 1) AS "wind_diff_lag2",
    ROUND("ma8_wind" - LAG("ma8_wind",3) OVER (ORDER BY "date"), 1) AS "wind_diff_lag3",
    ROUND("ma8_wind" - LAG("ma8_wind",4) OVER (ORDER BY "date"), 1) AS "wind_diff_lag4",
    ROUND("ma8_wind" - LAG("ma8_wind",5) OVER (ORDER BY "date"), 1) AS "wind_diff_lag5",
    ROUND("ma8_wind" - LAG("ma8_wind",6) OVER (ORDER BY "date"), 1) AS "wind_diff_lag6",
    ROUND("ma8_wind" - LAG("ma8_wind",7) OVER (ORDER BY "date"), 1) AS "wind_diff_lag7",
    ROUND("ma8_wind" - LAG("ma8_wind",8) OVER (ORDER BY "date"), 1) AS "wind_diff_lag8"

FROM ma
WHERE "date" >= '2019-01-09'        -- first day with full 8-day MA
ORDER BY "date";