WITH temp AS (   -- daily mean temperature (°F) averaged across LGA & JFK
    SELECT 
        TO_DATE(CONCAT("year",'-',LPAD("mo",2,'0'),'-',LPAD("da",2,'0')))      AS "date",
        AVG("temp")                                                            AS "avg_temp"
    FROM (
        SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2008 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2009 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2010 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
        UNION ALL SELECT "year","mo","da","temp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    ) g
    GROUP BY "date"
),

complaints AS (   -- 311 complaints 2008-2017
    SELECT 
        TO_DATE( TO_TIMESTAMP_LTZ( "created_date" / 1000000 ) )                AS "date",
        "complaint_type"
    FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
    WHERE "created_date" IS NOT NULL
          AND "complaint_type" IS NOT NULL
          AND TO_DATE( TO_TIMESTAMP_LTZ( "created_date" / 1000000 ) )
              BETWEEN '2008-01-01' AND '2017-12-31'
),

daily_counts AS (      -- count per type per day
    SELECT "date",
           "complaint_type",
           COUNT(*)                           AS cnt
    FROM complaints
    GROUP BY "date","complaint_type"
),

daily_totals AS (      -- total complaints per day
    SELECT "date",
           COUNT(*)                           AS total_cnt
    FROM complaints
    GROUP BY "date"
),

joined AS (            -- combine with temperature & compute daily percentage
    SELECT 
        t."date",
        t."avg_temp",
        dc."complaint_type",
        dc.cnt,
        dc.cnt / dt.total_cnt::FLOAT          AS cnt_pct
    FROM temp            t
    JOIN daily_totals dt ON dt."date" = t."date"
    JOIN daily_counts dc ON dc."date" = t."date"
)

SELECT 
    "complaint_type",
    SUM(cnt)                                        AS total_complaints,
    COUNT(*)                                        AS total_days,
    ROUND( CORR("avg_temp", cnt)      , 4)          AS corr_cnt,
    ROUND( CORR("avg_temp", cnt_pct)  , 4)          AS corr_pct
FROM joined
GROUP BY "complaint_type"
HAVING 
      SUM(cnt) > 5000
  AND (
        ABS( CORR("avg_temp", cnt) )     > 0.5
     OR ABS( CORR("avg_temp", cnt_pct) ) > 0.5
      )
ORDER BY "complaint_type";