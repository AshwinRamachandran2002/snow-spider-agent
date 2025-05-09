WITH daily_311 AS (   -- 311 complaints per day and type (2011-2020)
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1000000))       AS dt ,
        "complaint_type",
        COUNT(*)                                                  AS cnt
    FROM NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE "created_date" IS NOT NULL
      AND "complaint_type" IS NOT NULL
      AND TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1000000))
            BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY dt , "complaint_type"
),
daily_totals AS (      -- total complaints per day
    SELECT dt , SUM(cnt) AS tot_cnt
    FROM daily_311
    GROUP BY dt
),
daily_props AS (       -- daily proportions for every complaint type
    SELECT
        d.dt ,
        d."complaint_type" ,
        d.cnt / CAST(t.tot_cnt AS FLOAT) AS prop
    FROM daily_311 d
    JOIN daily_totals t
      ON d.dt = t.dt
),
complaint_totals AS (  -- overall counts (2011-2020)
    SELECT "complaint_type" , SUM(cnt) AS total_reqs
    FROM daily_311
    GROUP BY "complaint_type"
    HAVING total_reqs > 3000           -- keep only types with >3 000 requests
),
filtered_props AS (
    SELECT p.*
    FROM daily_props p
    JOIN complaint_totals c
      ON p."complaint_type" = c."complaint_type"
),
wind_raw AS (          -- union of needed columns only (avoids mismatch)
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 UNION ALL
    SELECT "stn","year","mo","da","wdsp" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020
),
wind AS (              -- daily mean wind speed (knots) at station 744860
    SELECT
        TO_DATE("year" || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS dt ,
        CAST("wdsp" AS FLOAT)                                                  AS wind_speed
    FROM wind_raw
    WHERE "stn" = '744860'
      AND TRY_CAST("wdsp" AS FLOAT) < 999     -- eliminate missing values
),
joined AS (            -- join proportions with wind by date
    SELECT
        p."complaint_type",
        p.prop,
        w.wind_speed
    FROM filtered_props p
    JOIN wind w
      ON p.dt = w.dt
),
corr_table AS (        -- Pearson correlation for each complaint type
    SELECT
        "complaint_type",
        CORR(prop , wind_speed) AS corr_val
    FROM joined
    GROUP BY "complaint_type"
),
ranked AS (            -- identify strongest positive & negative
    SELECT
        "complaint_type",
        corr_val,
        RANK() OVER (ORDER BY corr_val DESC) AS rk_pos,
        RANK() OVER (ORDER BY corr_val ASC)  AS rk_neg
    FROM corr_table
)
SELECT
    "complaint_type",
    ROUND(corr_val , 4) AS correlation
FROM ranked
WHERE rk_pos = 1            -- strongest positive
   OR rk_neg = 1            -- strongest negative
ORDER BY correlation DESC NULLS LAST;