/*  1)  Daily mean wind-speed at JFK (station 744860) for 2011-2020
    2)  Daily 311 complaint totals and per-type counts
    3)  For every complaint type with ≥3000 requests (2011-2020) compute
        Pearson correlation between its daily proportion (cnt/total)
        and the daily mean wind-speed
    4)  Return the types with the strongest positive and strongest negative
        correlations (rounded to 4 decimals)
*/
WITH
-- ------------------------------------------------------------------
-- Weather: mean wind speed per day at JFK airport
-- ------------------------------------------------------------------
weather AS (
    SELECT
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) AS "date",
        NULLIF("wdsp",'999.9')::FLOAT               AS "wdsp"
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011   WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')), NULLIF("wdsp",'999.9')::FLOAT
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020 WHERE "stn"='744860'
),
weather_filtered AS (
    SELECT *
    FROM   weather
    WHERE  "date" BETWEEN '2011-01-01' AND '2020-12-31'
          AND "wdsp" IS NOT NULL
),
-- ------------------------------------------------------------------
-- 311 complaints (2011-2020)
-- ------------------------------------------------------------------
complaints AS (
    SELECT
        CAST(TO_TIMESTAMP("created_date"/1000000) AS DATE)  AS "date",
        "complaint_type"
    FROM  NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE CAST(TO_TIMESTAMP("created_date"/1000000) AS DATE)
          BETWEEN '2011-01-01' AND '2020-12-31'
          AND "complaint_type" IS NOT NULL
),
-- total requests per type over the whole period
type_totals AS (
    SELECT "complaint_type",
           COUNT(*) AS total_requests
    FROM   complaints
    GROUP  BY "complaint_type"
    HAVING COUNT(*) > 3000          -- threshold
),
-- daily totals (all complaints)
daily_totals AS (
    SELECT "date",
           COUNT(*) AS total_daily
    FROM   complaints
    GROUP  BY "date"
),
-- daily counts for each type
daily_type_counts AS (
    SELECT "date",
           "complaint_type",
           COUNT(*) AS cnt
    FROM   complaints
    GROUP  BY "date","complaint_type"
),
-- ------------------------------------------------------------------
-- Correlation calculation
-- ------------------------------------------------------------------
correlations AS (
    SELECT
        tt."complaint_type",
        CORR( COALESCE(dtc.cnt,0) / dt.total_daily::FLOAT,
              wf."wdsp" )                                AS corr_coef
    FROM            type_totals      tt
    CROSS JOIN      weather_filtered wf
    JOIN            daily_totals     dt
                 ON dt."date" = wf."date"
    LEFT JOIN       daily_type_counts dtc
                 ON dtc."date" = wf."date"
                AND dtc."complaint_type" = tt."complaint_type"
    GROUP BY tt."complaint_type"
),
-- rank to find strongest positive and negative
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY corr_coef DESC) AS pos_rank,
           RANK() OVER (ORDER BY corr_coef ASC)  AS neg_rank
    FROM   correlations
)
-- ------------------------------------------------------------------
-- Final output
-- ------------------------------------------------------------------
SELECT
    "complaint_type",
    ROUND(corr_coef,4) AS correlation
FROM   ranked
WHERE  pos_rank = 1
   OR  neg_rank = 1
ORDER BY correlation DESC NULLS LAST;