WITH complaints_raw AS (          -- all 311 complaints having a complaint type
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ("created_date" / 1000000)) AS comp_date,
        "complaint_type"
    FROM NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
    WHERE "complaint_type" IS NOT NULL
),
complaints_10yr AS (              -- restrict to 2011-01-01 … 2020-12-31
    SELECT *
    FROM complaints_raw
    WHERE comp_date BETWEEN '2011-01-01' AND '2020-12-31'
),
totals_by_type AS (               -- total requests per complaint type (10-year window)
    SELECT
        "complaint_type",
        COUNT(*) AS total_requests
    FROM complaints_10yr
    GROUP BY "complaint_type"
),
daily_comp AS (                   -- daily counts for each complaint type
    SELECT
        comp_date AS day,
        "complaint_type",
        COUNT(*)  AS type_cnt
    FROM complaints_10yr
    GROUP BY comp_date, "complaint_type"
),
daily_tot AS (                    -- total 311 complaints per day
    SELECT
        day,
        SUM(type_cnt) AS day_total
    FROM daily_comp
    GROUP BY day
),
daily_props AS (                  -- proportion of each complaint type per day
    SELECT
        d.day,
        d."complaint_type",
        d.type_cnt,
        d.type_cnt / dt.day_total AS prop
    FROM daily_comp d
    JOIN daily_tot dt ON dt.day = d.day
),
/* -------------------------------------------------------------------- */
/*  NOAA GSOD – union of 2011-2020 files (only the columns we need)     */
gsod_union AS (
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019 UNION ALL
    SELECT "year","mo","da","wdsp","stn" FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020
),
wind_daily AS (                   -- daily mean wind speed (knots) at JFK (station 744860)
    SELECT
        TO_DATE("year" || '-' || LPAD("mo",2,'0') || '-' || LPAD("da",2,'0')) AS day,
        AVG(TRY_TO_NUMBER("wdsp")) AS wdsp
    FROM gsod_union
    WHERE "stn" = '744860'
      AND TRY_TO_NUMBER("wdsp") IS NOT NULL
      AND TRY_TO_NUMBER("wdsp") <> 999.9          -- 999.9 = missing flag
    GROUP BY day
),
/* -------------------------------------------------------------------- */
joined AS (                       -- join proportions with wind data
    SELECT
        p.day,
        p."complaint_type",
        p.prop,
        w.wdsp
    FROM daily_props p
    JOIN wind_daily w ON w.day = p.day
),
corr_by_type AS (                 -- Pearson correlation for each complaint type
    SELECT
        j."complaint_type",
        CORR(j.prop , j.wdsp) AS corr_coef
    FROM joined j
    GROUP BY j."complaint_type"
    HAVING EXISTS (               -- retain only types with > 3000 total requests
        SELECT 1
        FROM totals_by_type t
        WHERE t."complaint_type" = j."complaint_type"
          AND t.total_requests > 3000
    )
),
/* strongest positive correlation */
pos AS (
    SELECT
        'Strongest_Positive' AS relation,
        "complaint_type",
        ROUND(corr_coef,4)   AS correlation
    FROM (
        SELECT
            "complaint_type",
            corr_coef,
            ROW_NUMBER() OVER (ORDER BY corr_coef DESC) AS rn
        FROM corr_by_type
    )
    WHERE rn = 1
),
/* strongest negative correlation */
neg AS (
    SELECT
        'Strongest_Negative' AS relation,
        "complaint_type",
        ROUND(corr_coef,4)   AS correlation
    FROM (
        SELECT
            "complaint_type",
            corr_coef,
            ROW_NUMBER() OVER (ORDER BY corr_coef ASC) AS rn
        FROM corr_by_type
    )
    WHERE rn = 1
)
/* -------------------------------------------------------------------- */
SELECT * FROM pos
UNION ALL
SELECT * FROM neg;