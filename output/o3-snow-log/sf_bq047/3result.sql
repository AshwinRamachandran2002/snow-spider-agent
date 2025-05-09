WITH
/*-------------- 1.  DAILY TEMPERATURE (°F) --------------*/
TEMP_RAW AS (
    /* 2008 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da"))           AS "temp_date",
           "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2008
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2009 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2009
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2010 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2010
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2011 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2011
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2012 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2012
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2013 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2013
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2014 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2014
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2015 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2015
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2016 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2016
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
        
    UNION ALL
    /* 2017 */
    SELECT DATE_FROM_PARTS(TO_NUMBER("year"),TO_NUMBER("mo"),TO_NUMBER("da")), "temp"
    FROM   NEW_YORK_NOAA.NOAA_GSOD.GSOD2017
    WHERE  "stn" IN ('725030','744860') AND "temp" <> 9999.9
),
TEMP_DAILY AS (       /* average of the two airports */
    SELECT "temp_date",
           AVG("temp") AS "avg_temp"
    FROM   TEMP_RAW
    GROUP  BY "temp_date"
),

/*-------------- 2.  DAILY 311 COMPLAINT COUNTS --------------*/
COMPLAINTS_DAILY AS (
    SELECT TO_DATE(TO_TIMESTAMP_LTZ("created_date"/1000000)) AS "event_date",
           "complaint_type",
           COUNT(*)                                         AS "daily_count"
    FROM   NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE  "created_date" IS NOT NULL
      AND  TO_DATE(TO_TIMESTAMP_LTZ("created_date"/1000000))
           BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP  BY "event_date","complaint_type"
),
TOTAL_DAILY AS (
    SELECT "event_date",
           SUM("daily_count") AS "total_daily_count"
    FROM   COMPLAINTS_DAILY
    GROUP  BY "event_date"
),

/*-------------- 3.  JOIN COUNTS WITH TEMPERATURE --------------*/
JOINED AS (
    SELECT c."event_date",
           c."complaint_type",
           c."daily_count",
           t."avg_temp",
           td."total_daily_count",
           c."daily_count" / td."total_daily_count"          AS "daily_pct"
    FROM   COMPLAINTS_DAILY c
           JOIN TOTAL_DAILY td ON c."event_date" = td."event_date"
           JOIN TEMP_DAILY  t  ON c."event_date" = t."temp_date"
),

/*-------------- 4.  CORRELATION & SUMMARY --------------*/
STATS AS (
    SELECT  "complaint_type",
            SUM("daily_count")                          AS "total_complaints",
            COUNT(*)                                    AS "total_days",
            CORR("avg_temp","daily_count")              AS "corr_cnt",
            CORR("avg_temp","daily_pct")                AS "corr_pct"
    FROM    JOINED
    GROUP   BY "complaint_type"
)

/*-------------- 5.  FINAL FILTER & OUTPUT --------------*/
SELECT  "complaint_type",
        "total_complaints",
        "total_days",
        ROUND("corr_cnt",4)      AS "corr_temp_count",
        ROUND("corr_pct",4)      AS "corr_temp_pct"
FROM    STATS
WHERE   "total_complaints" > 5000
  AND   ABS("corr_cnt")  > 0.5
ORDER BY "complaint_type";