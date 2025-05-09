WITH requests AS (      -- 311 requests 2011-2020
    SELECT
        DATE_TRUNC('day', TO_TIMESTAMP("created_date" / 1000000)) AS day ,
        "complaint_type"
    FROM   NEW_YORK_NOAA.NEW_YORK."_311_SERVICE_REQUESTS"
    WHERE  "created_date" BETWEEN 1293840000000000            -- 2011-01-01
                              AND     1609459199000000        -- 2020-12-31 23:59:59
      AND "complaint_type" IS NOT NULL
),

daily_totals AS (       -- total complaints per day
    SELECT day , COUNT(*) AS total_complaints
    FROM   requests
    GROUP  BY day
),

daily_type_counts AS (  -- complaints of each type per day
    SELECT day , "complaint_type" , COUNT(*) AS type_count
    FROM   requests
    GROUP  BY day , "complaint_type"
),

type_totals AS (        -- complaint types with > 3 000 total requests
    SELECT "complaint_type" ,
           SUM(type_count) AS total_type_count
    FROM   daily_type_counts
    GROUP  BY "complaint_type"
    HAVING SUM(type_count) > 3000
),

daily_proportions AS (  -- proportion of each type each day
    SELECT
        d.day ,
        d."complaint_type" ,
        d.type_count / dt.total_complaints::FLOAT AS proportion
    FROM  daily_type_counts d
    JOIN  type_totals       t  ON t."complaint_type" = d."complaint_type"
    JOIN  daily_totals      dt ON dt.day = d.day
),

-- =======================  GSOD WIND DATA  ========================
wind_union AS (         -- select identical column list from each table
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

wind_raw AS (           -- keep JFK station & clean wind-speed
    SELECT
        TO_DATE("year" || LPAD("mo",2,'0') || LPAD("da",2,'0'),'YYYYMMDD') AS day ,
        CASE WHEN TO_NUMBER("wdsp") = 999.9 THEN NULL
             ELSE TO_NUMBER("wdsp") END                                  AS wind_speed
    FROM   wind_union
    WHERE  "stn" = '744860'
),

wind AS (               -- daily average wind speed (already daily)
    SELECT day , AVG(wind_speed) AS wind_speed
    FROM   wind_raw
    WHERE  wind_speed IS NOT NULL
    GROUP  BY day
),

joined AS (             -- join complaint proportions with wind
    SELECT
        dp."complaint_type" ,
        dp.proportion ,
        w.wind_speed
    FROM   daily_proportions dp
    JOIN   wind            w  ON w.day = dp.day
),

correlations AS (       -- Pearson correlations per complaint type
    SELECT
        "complaint_type" ,
        CORR(proportion , wind_speed) AS corr_coef
    FROM   joined
    GROUP  BY "complaint_type"
),

ranked AS (             -- strongest positive & negative correlations
    SELECT
        "complaint_type" ,
        corr_coef ,
        RANK() OVER (ORDER BY corr_coef DESC) AS pos_rank ,
        RANK() OVER (ORDER BY corr_coef ASC)  AS neg_rank
    FROM   correlations
)

SELECT
    "complaint_type",
    ROUND(corr_coef , 4) AS correlation_coefficient
FROM   ranked
WHERE  pos_rank = 1 OR neg_rank = 1
ORDER  BY correlation_coefficient DESC NULLS LAST;