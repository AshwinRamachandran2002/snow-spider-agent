WITH temperature AS (   -- 1.  build daily mean-temperature series (average of LGA & JFK)
    SELECT 
        TO_DATE(CONCAT("year",'-',LPAD("mo",2,'0'),'-',LPAD("da",2,'0')))                AS dt ,
        AVG("temp")                                                                      AS avg_temp
    FROM (   -- explicit UNION of the 10 GSOD yearly tables 2008-2017
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2008 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2009 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2010 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 UNION ALL
        SELECT * FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017
    ) g
    WHERE g."stn" IN ('725030' , '744860')        -- LaGuardia and JFK
      AND g."temp" <> 9999.9                      -- discard missing values
    GROUP BY dt
),
complaints_raw AS (   -- 2.  keep 311 complaints in 2008-2017 period
    SELECT 
        TO_DATE( TO_TIMESTAMP_LTZ( "created_date" / 1000000 ) )          AS dt ,
        "complaint_type"
    FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
    WHERE "created_date" IS NOT NULL
      AND "complaint_type" IS NOT NULL
      AND TO_DATE( TO_TIMESTAMP_LTZ( "created_date" / 1000000 ) )
          BETWEEN '2008-01-01' AND '2017-12-31'
),
daily_counts AS (      -- 3.  count complaints per type per day
    SELECT dt ,
           "complaint_type" ,
           COUNT(*) AS daily_count
    FROM complaints_raw
    GROUP BY dt , "complaint_type"
),
totals AS (            -- 4.  complaint types with >5 000 total events
    SELECT "complaint_type" ,
           SUM(daily_count) AS total_complaints
    FROM   daily_counts
    GROUP BY "complaint_type"
    HAVING SUM(daily_count) > 5000
),
grid AS (              -- 5.  dense matrix: every temp-day × every selected complaint type
    SELECT 
        t.dt ,
        tot."complaint_type" ,
        COALESCE(dc.daily_count , 0)          AS daily_count ,
        tot.total_complaints ,
        t.avg_temp
    FROM temperature t
    CROSS JOIN totals      tot
    LEFT JOIN  daily_counts dc
           ON  dc.dt              = t.dt
           AND dc."complaint_type"= tot."complaint_type"
),
summary AS (           -- 6.  correlations
    SELECT
        "complaint_type",
        total_complaints,
        COUNT(*)                                         AS total_days,
        CORR( daily_count::FLOAT ,     avg_temp )        AS corr_cnt,
        CORR( (daily_count::FLOAT)/NULLIF(total_complaints,0) ,
              avg_temp )                                 AS corr_pct
    FROM grid
    GROUP BY "complaint_type", total_complaints
)
-- 7.  final answer: strong correlations (|r| > 0.5) and rounded to 4 dp
SELECT
    "complaint_type",
    total_complaints,
    total_days,
    ROUND(corr_cnt , 4)  AS corr_count_temperature,
    ROUND(corr_pct , 4)  AS corr_pct_temperature
FROM summary
WHERE ABS(corr_cnt) > 0.5
   OR ABS(corr_pct) > 0.5
ORDER BY "complaint_type";