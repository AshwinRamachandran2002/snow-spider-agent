WITH temp_raw AS (      -- 1)  Daily mean-temperature for LGA (725030) & JFK (744860)
    SELECT
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))          AS "dt",
        CAST("temp" AS FLOAT)                                                  AS "temp",
        "stn"
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2008  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2009  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2010  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
    UNION ALL SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), CAST("temp" AS FLOAT),"stn"
        FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017  WHERE "stn" IN ('725030','744860') AND "temp" <> 9999.9
),
daily_temp AS (          -- 2)  Average the two airports → one NYC temperature per day
    SELECT "dt",
           AVG("temp")  AS "avg_temp"
    FROM   temp_raw
    GROUP  BY "dt"
),

complaints_raw AS (      -- 3)  311 complaints converted to dates 2008-2017
    SELECT
        DATE_TRUNC('DAY',
                   TO_TIMESTAMP("created_date"/1000000))::DATE               AS "dt",
        "complaint_type"
    FROM NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE "created_date" IS NOT NULL
      AND DATE_TRUNC('YEAR',
            DATE_TRUNC('DAY',TO_TIMESTAMP("created_date"/1000000))) BETWEEN '2008-01-01' AND '2017-12-31'
),

daily_counts AS (        -- 4)  Daily count per complaint type
    SELECT "dt",
           "complaint_type",
           COUNT(*)  AS "cnt"
    FROM   complaints_raw
    GROUP  BY "dt","complaint_type"
),

daily_totals AS (        -- 5)  Daily total complaints (all types)
    SELECT "dt",
           SUM("cnt") AS "total_cnt"
    FROM   daily_counts
    GROUP  BY "dt"
),

joined AS (              -- 6)  Join counts with temperature and percentages
    SELECT
        dc."dt",
        dt."avg_temp",
        dc."complaint_type",
        dc."cnt",
        dc."cnt" / dtot."total_cnt"::FLOAT   AS "pct_of_day"
    FROM   daily_counts dc
           JOIN daily_totals dtot ON dc."dt" = dtot."dt"
           JOIN daily_temp   dt    ON dc."dt" = dt."dt"
),

stats AS (               -- 7)  Correlations & overall tallies
    SELECT
        "complaint_type",
        SUM("cnt")                              AS "total_complaints",
        COUNT(*)                                AS "days_with_valid_temp",
        CORR("avg_temp","cnt")                  AS "corr_cnt",
        CORR("avg_temp","pct_of_day")           AS "corr_pct"
    FROM   joined
    GROUP  BY "complaint_type"
),

filtered AS (            -- 8)  Apply thresholds
    SELECT
        "complaint_type",
        "total_complaints",
        "days_with_valid_temp",
        ROUND("corr_cnt",4)   AS "corr_cnt",
        ROUND("corr_pct",4)   AS "corr_pct"
    FROM   stats
    WHERE "total_complaints" > 5000
      AND (ABS("corr_cnt") > 0.5 OR ABS("corr_pct") > 0.5)
)

-- 9)  Final result
SELECT *
FROM   filtered
ORDER  BY "complaint_type";