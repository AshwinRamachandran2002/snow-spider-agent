WITH temp_raw AS (   -- 1.  Daily mean temperatures for LaGuardia (725030) & JFK (744860)
    SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))                                              AS "date",
           CAST("temp" AS FLOAT)                                                                                                   AS "temp_f"
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2008
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    
    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2009
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2010
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9

    UNION ALL SELECT TO_DATE(TO_VARCHAR("year")||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT)
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017
    WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
),
temp_aggr AS (       -- average of the two airports per day
    SELECT "date",
           AVG("temp_f") AS "temp_f"
    FROM   temp_raw
    GROUP  BY "date"
),
complaints_raw AS (  -- 2.  311 complaints (2008-2017)
    SELECT DATE_TRUNC('day',
           TO_TIMESTAMP_NTZ("created_date"/1000000))                AS "date",
           "complaint_type"
    FROM   NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE  "created_date" IS NOT NULL
      AND  DATE_TRUNC('day',
           TO_TIMESTAMP_NTZ("created_date"/1000000)) 
           BETWEEN '2008-01-01'::date AND '2017-12-31'::date
),
daily_counts AS (    -- daily count per complaint type
    SELECT "date",
           "complaint_type",
           COUNT(*) AS "cnt"
    FROM   complaints_raw
    GROUP  BY "date", "complaint_type"
),
daily_totals AS (    -- total complaints each day
    SELECT "date",
           SUM("cnt") AS "total_cnt"
    FROM   daily_counts
    GROUP  BY "date"
),
daily_with_pct AS (  -- add daily percentage
    SELECT dc."date",
           dc."complaint_type",
           dc."cnt",
           dc."cnt" / dt."total_cnt"::FLOAT AS "pct"
    FROM   daily_counts dc
    JOIN   daily_totals dt
      ON   dc."date" = dt."date"
),
combined AS (        -- join with temperature, keep only days with valid temp
    SELECT d."complaint_type",
           d."cnt",
           d."pct",
           t."temp_f"
    FROM   daily_with_pct d
    JOIN   temp_aggr     t
      ON   d."date" = t."date"
),
totals_per_type AS ( -- total complaints per type (filter >5000)
    SELECT "complaint_type",
           SUM("cnt") AS total_complaints
    FROM   combined
    GROUP  BY "complaint_type"
    HAVING SUM("cnt") > 5000
),
corrs AS (           -- 3.  Pearson correlations
    SELECT c."complaint_type",
           COUNT(*)                                  AS days_with_temp,
           CORR(c."temp_f", c."cnt")                 AS corr_cnt,
           CORR(c."temp_f", c."pct")                 AS corr_pct
    FROM   combined c
    JOIN   totals_per_type t
      ON   c."complaint_type" = t."complaint_type"
    GROUP  BY c."complaint_type"
)
-- 4.  Final result: only strongly correlated (|corr| > 0.5)
SELECT tp."complaint_type",
       tp.total_complaints,
       cr.days_with_temp,
       ROUND(cr.corr_cnt,  4) AS corr_with_count,
       ROUND(cr.corr_pct,  4) AS corr_with_percentage
FROM   totals_per_type tp
JOIN   corrs          cr
  ON   tp."complaint_type" = cr."complaint_type"
WHERE  ABS(cr.corr_cnt) >= 0.5
    OR ABS(cr.corr_pct) >= 0.5
ORDER  BY tp.total_complaints DESC NULLS LAST;