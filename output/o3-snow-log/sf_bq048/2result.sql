WITH complaints AS (   -- convert raw timestamps to dates and keep needed columns
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1000000)) AS day,
        "complaint_type"
    FROM NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE "created_date" IS NOT NULL
),
daily_counts AS (      -- number of complaints of each type per day (2011-2020)
    SELECT
        day,
        "complaint_type",
        COUNT(*)                                        AS cnt
    FROM complaints
    WHERE day BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY day, "complaint_type"
),
total_counts AS (      -- total 311 complaints each day
    SELECT
        day,
        SUM(cnt)                                       AS total_cnt
    FROM daily_counts
    GROUP BY day
),
daily_props AS (       -- proportion of each complaint type each day
    SELECT
        d.day,
        d."complaint_type",
        d.cnt::FLOAT / t.total_cnt                     AS prop
    FROM daily_counts d
    JOIN total_counts t
          ON d.day = t.day
),
complaint_totals AS (  -- keep only complaint types with > 3 000 requests
    SELECT
        "complaint_type",
        SUM(cnt)                                       AS total_requests
    FROM daily_counts
    GROUP BY "complaint_type"
    HAVING total_requests > 3000
),
-- union daily wind-speed data from JFK station (744860) for 2011-2020
wind_union AS (
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))) AS day,
           TRY_TO_DOUBLE("wdsp")                           AS wind
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019  WHERE "stn"='744860'
    UNION ALL
    SELECT TO_DATE(TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0'))), TRY_TO_DOUBLE("wdsp")
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020  WHERE "stn"='744860'
),
wind_daily AS (
    SELECT  day,  wind
    FROM    wind_union
    WHERE   wind IS NOT NULL
      AND   wind < 999                       -- drop obvious missing codes
      AND   day BETWEEN '2011-01-01' AND '2020-12-31'
),
corr_by_type AS (      -- Pearson correlation between daily proportion & wind
    SELECT
        dp."complaint_type",
        CORR(dp.prop, w.wind)                     AS corr_coeff
    FROM daily_props        dp
    JOIN wind_daily         w   ON dp.day = w.day
    JOIN complaint_totals   ct  ON dp."complaint_type" = ct."complaint_type"
    GROUP BY dp."complaint_type"
    HAVING corr_coeff IS NOT NULL
)

-- strongest positive and strongest (most) negative correlations
SELECT
    "complaint_type",
    ROUND(corr_coeff, 4)                          AS correlation_coefficient
FROM (
        (SELECT * FROM corr_by_type ORDER BY corr_coeff DESC NULLS LAST LIMIT 1)
     UNION ALL
        (SELECT * FROM corr_by_type ORDER BY corr_coeff ASC NULLS LAST LIMIT 1)
);