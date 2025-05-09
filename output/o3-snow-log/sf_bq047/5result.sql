WITH
/*-----------------------------------------------------------
1.  DAILY MEAN AIR-TEMPERATURE (°F) – average of LaGuardia
    (STN = 725030) and JFK (STN = 744860) for each calendar day
    2008-01-01 through 2017-12-31.  9999.9 values are discarded.
-----------------------------------------------------------*/
TEMP_DAILY AS (
    SELECT
        TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) AS day,
        AVG("temp") AS temp_f
    FROM (
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
    ) gs
    WHERE gs."stn" IN ('725030','744860')
      AND gs."temp" <> 9999.9
      AND TO_DATE("year" || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0'))
            BETWEEN '2008-01-01' AND '2017-12-31'
    GROUP BY day
),
/*-----------------------------------------------------------
2.  DAILY 311 COMPLAINT COUNTS BY TYPE (same 10-yr window)
-----------------------------------------------------------*/
COMPLAINTS_DAILY AS (
    SELECT
        DATE_TRUNC('DAY', TO_TIMESTAMP("created_date" / 1000000))::DATE AS day,
        "complaint_type"                                                AS ctype,
        COUNT(*)                                                        AS cnt
    FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
    WHERE TO_TIMESTAMP("created_date" / 1000000)
          BETWEEN '2008-01-01' AND '2017-12-31 23:59:59'
    GROUP BY day, "complaint_type"
),
/*-----------------------------------------------------------
3.  TOTAL COUNTS PER COMPLAINT TYPE – keep only those > 5000
-----------------------------------------------------------*/
CTYPE_TOTAL AS (
    SELECT
        ctype,
        SUM(cnt) AS total_cnt
    FROM COMPLAINTS_DAILY
    GROUP BY ctype
    HAVING SUM(cnt) > 5000
),
/*-----------------------------------------------------------
4.  COMPLETE DAILY PANEL WITH ZERO-FILL FOR MISSING DAYS
-----------------------------------------------------------*/
DAILY_PANEL AS (
    SELECT
        t.day,
        t.temp_f,
        ct.ctype,
        COALESCE(cd.cnt, 0)        AS cnt,
        ct.total_cnt
    FROM TEMP_DAILY t
    CROSS JOIN CTYPE_TOTAL ct
    LEFT JOIN COMPLAINTS_DAILY cd
           ON cd.day = t.day AND cd.ctype = ct.ctype
)
/*-----------------------------------------------------------
5.  CORRELATION & FINAL OUTPUT
-----------------------------------------------------------*/
SELECT
    ctype                               AS "COMPLAINT_TYPE",
    total_cnt                           AS "TOTAL_COMPLAINTS",
    COUNT(*)                            AS "TOTAL_DAYS",
    ROUND(CORR(temp_f, cnt)          ,4) AS "CORR_CNT",
    ROUND(CORR(temp_f, cnt / total_cnt),4) AS "CORR_PCT"
FROM DAILY_PANEL
GROUP BY ctype, total_cnt
HAVING ABS(CORR(temp_f, cnt)) > 0.5
ORDER BY "COMPLAINT_TYPE";