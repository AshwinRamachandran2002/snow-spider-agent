WITH temps AS (   /* daily mean temperature (°F) averaged over LGA 725030 & JFK 744860 */
    SELECT
        dt   AS date ,                          -- calendar day
        AVG("temp") AS avg_temp                 -- mean of available stations
    FROM (
        /* ---------- 2008 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) AS dt , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2008
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2009 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2009
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2010 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2010
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2011 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2012 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2013 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2014 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2015 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2016 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
        UNION ALL
        /* ---------- 2017 ---------- */
        SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) , "temp"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017
        WHERE "stn" IN ('725030','744860') AND "temp" < 9000
    ) all_t
    GROUP BY dt
), complaints_daily AS (   /* daily complaint counts (all NYC) */
    SELECT
        "complaint_type"                                       AS complaint_type,
        DATE_TRUNC('DAY', TO_TIMESTAMP("created_date"/1000000)) AS date,
        COUNT(*)                                               AS daily_count
    FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
    WHERE "created_date" IS NOT NULL
      AND DATE_TRUNC('DAY', TO_TIMESTAMP("created_date"/1000000))
          BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP BY complaint_type, date
), complaint_totals AS (   /* keep types with > 5 000 incidents */
    SELECT complaint_type,
           SUM(daily_count) AS total_count
    FROM complaints_daily
    GROUP BY complaint_type
    HAVING total_count > 5000
), base AS (   /* join every valid-temperature day to each retained complaint type */
    SELECT
        ct.complaint_type,
        t.date,
        COALESCE(cd.daily_count, 0)  AS daily_count,
        t.avg_temp,
        ct.total_count
    FROM complaint_totals        ct
    CROSS JOIN temps             t
    LEFT JOIN complaints_daily   cd
           ON cd.complaint_type = ct.complaint_type
          AND cd.date           = t.date
)
SELECT
    complaint_type,
    total_count                                   AS total_complaints,
    COUNT(*)                                      AS days_with_valid_temperature,
    ROUND(CORR(avg_temp, daily_count) , 4)        AS corr_daily_count,
    ROUND(CORR(avg_temp,
               daily_count * 1.0 / total_count) , 4) AS corr_daily_percentage
FROM base
GROUP BY complaint_type, total_count
HAVING ABS(CORR(avg_temp, daily_count))                > 0.5
   OR ABS(CORR(avg_temp, daily_count * 1.0 / total_count)) > 0.5
ORDER BY complaint_type;