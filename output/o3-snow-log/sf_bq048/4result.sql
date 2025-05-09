/*  Complaint-wind correlations 2011-2020  */
WITH wind AS (   -- Daily mean wind speed (knots) at JFK (station 744860)
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),
                           CAST("mo"   AS INT),
                           CAST("da"   AS INT))              AS day,
           CAST("wdsp" AS FLOAT)                             AS wind_speed
    FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
    UNION ALL
    SELECT DATE_FROM_PARTS(CAST("year" AS INT),CAST("mo" AS INT),CAST("da" AS INT)),CAST("wdsp" AS FLOAT)
      FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020  WHERE "stn"='744860' AND CAST("wdsp" AS FLOAT) < 990
),
complaints_raw AS (   -- 311 complaints 2011-2020
    SELECT CAST(TO_TIMESTAMP("created_date"/1000000) AS DATE) AS day,
           "complaint_type"  complaint_type            -- alias unquoted for case-insensitivity
    FROM   NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE  "created_date" IS NOT NULL
      AND  "complaint_type" IS NOT NULL
      AND  CAST(TO_TIMESTAMP("created_date"/1000000) AS DATE)
           BETWEEN '2011-01-01' AND '2020-12-31'
),
daily_tot AS (        -- total complaints per day
    SELECT day,
           COUNT(*) AS daily_total
    FROM   complaints_raw
    GROUP  BY day
),
daily_type AS (       -- daily counts by type
    SELECT day,
           complaint_type,
           COUNT(*) AS daily_type_cnt
    FROM   complaints_raw
    GROUP  BY day, complaint_type
),
type_totals AS (      -- keep types with >3000 requests
    SELECT complaint_type,
           SUM(daily_type_cnt) AS total_requests
    FROM   daily_type
    GROUP  BY complaint_type
    HAVING SUM(daily_type_cnt) > 3000
),
daily_props AS (      -- daily proportion per retained type
    SELECT dt.day,
           dt.complaint_type,
           CAST(dt.daily_type_cnt AS FLOAT) / dtot.daily_total  AS proportion
    FROM   daily_type dt
           JOIN daily_tot   dtot ON dt.day = dtot.day
           JOIN type_totals tt   ON dt.complaint_type = tt.complaint_type
),
joined AS (           -- add wind
    SELECT p.complaint_type,
           p.proportion,
           w.wind_speed
    FROM   daily_props p
           JOIN wind w ON p.day = w.day
),
corrs AS (            -- Pearson correlation per type
    SELECT complaint_type,
           CORR(proportion, wind_speed) AS corr_coeff
    FROM   joined
    GROUP  BY complaint_type
),
ranks AS (            -- ranks for strongest + / -
    SELECT complaint_type,
           corr_coeff,
           ROW_NUMBER() OVER (ORDER BY corr_coeff DESC) AS pos_rank,
           ROW_NUMBER() OVER (ORDER BY corr_coeff ASC)  AS neg_rank
    FROM   corrs
)
SELECT complaint_type,
       ROUND(corr_coeff, 4) AS correlation
FROM   ranks
WHERE  pos_rank = 1
   OR  neg_rank = 1
ORDER BY correlation DESC NULLS LAST;