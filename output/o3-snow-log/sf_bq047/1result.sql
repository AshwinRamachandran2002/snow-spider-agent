WITH temp_union AS (          -- 1.  Daily-level temperature for LGA (725030) & JFK (744860)
    SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2008 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2009 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2010 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 WHERE "stn" IN ('725030','744860') AND "temp"<9000
    UNION ALL SELECT "year","mo","da","temp","stn"  FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 WHERE "stn" IN ('725030','744860') AND "temp"<9000
),
temp_daily AS (               -- average the two airports (when both present)
    SELECT
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))          AS "date",
        AVG("temp")                                                           AS avg_temp
    FROM temp_union
    GROUP BY "date"
),
complaint_raw AS (            -- 2. 310 complaints restricted to study period
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("created_date"/1000000)) AS dt,
        "complaint_type"
    FROM NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE TO_DATE(TO_TIMESTAMP_NTZ("created_date"/1000000))
          BETWEEN '2008-01-01' AND '2017-12-31'
),
complaint_daily AS (          -- daily counts per type
    SELECT dt,
           "complaint_type",
           COUNT(*) AS daily_count
    FROM complaint_raw
    GROUP BY dt, "complaint_type"
),
complaint_total AS (          -- complaint types with >5 000 occurrences
    SELECT "complaint_type",
           SUM(daily_count) AS total_complaints
    FROM complaint_daily
    GROUP BY "complaint_type"
    HAVING SUM(daily_count) > 5000
),
corr_prep AS (                -- 3.  build day-level panel: every temp day × selected type
    SELECT
        t."date",
        ct."complaint_type",
        NVL(cd.daily_count,0)                 AS daily_count,
        ct.total_complaints,
        t.avg_temp
    FROM temp_daily                t
    JOIN complaint_total           ct                    -- cross join to repeat every type
      ON 1=1
    LEFT JOIN complaint_daily      cd
      ON cd.dt              = t."date"
     AND cd."complaint_type" = ct."complaint_type"
),
corrs AS (                     -- 4.  correlations
    SELECT
        "complaint_type",
        MAX(total_complaints)                            AS total_complaints,
        COUNT(*)                                         AS total_temp_days,
        CORR(avg_temp, daily_count)                      AS corr_count,
        CORR(avg_temp, daily_count/total_complaints)     AS corr_pct
    FROM corr_prep
    GROUP BY "complaint_type"
)
SELECT
    "complaint_type",
    total_complaints,
    total_temp_days,
    ROUND(corr_count,4) AS corr_with_daily_count,
    ROUND(corr_pct ,4) AS corr_with_daily_pct
FROM corrs
WHERE ABS(corr_count) > 0.5 OR ABS(corr_pct) > 0.5      -- strong correlation
ORDER BY ABS(corr_count) DESC NULLS LAST;