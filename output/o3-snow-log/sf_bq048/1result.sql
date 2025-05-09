/* Find complaint types ( >3,000 requests, 2011-2020 ) whose daily share
   of 311 calls shows the strongest positive and negative correlation with
   daily mean wind speed measured at JFK airport (GSOD station 744860). */

WITH complaints_raw AS (                       -- 311 requests with day stamp
    SELECT
        "complaint_type"                                           AS complaint_type ,
        DATE_TRUNC('day', TO_TIMESTAMP("created_date" / 1000000))  AS d
    FROM NEW_YORK_NOAA.NEW_YORK._311_SERVICE_REQUESTS
    WHERE "complaint_type" IS NOT NULL
      AND "created_date"  IS NOT NULL
),

complaint_counts AS (                          -- daily counts by complaint type
    SELECT
        complaint_type ,
        d ,
        COUNT(*) AS complaint_count
    FROM complaints_raw
    WHERE d BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY complaint_type , d
),

daily_totals AS (                              -- total 311 requests per day
    SELECT
        d ,
        COUNT(*) AS total_count
    FROM complaints_raw
    WHERE d BETWEEN '2011-01-01' AND '2020-12-31'
    GROUP BY d
),

/* union GSOD tables 2011-2020, quoting columns exactly as stored
   (lower-case in this dataset) and rename “year” → yr for ease of use */
gsod_union AS (
          SELECT "stn" , "year" AS yr , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2011
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2012
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2013
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2014
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2015
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2016
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2017
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2018
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2019
 UNION ALL SELECT "stn" , "year"     , "mo" , "da" , "wdsp"
          FROM NEW_YORK_NOAA.NOAA_GSOD.GSOD2020
),

gsod_jfk AS (                                  -- daily mean wind speed at JFK
    SELECT
        TO_DATE(yr||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) AS d ,
        CAST("wdsp" AS FLOAT)                                     AS wind_speed
    FROM gsod_union
    WHERE "stn" = '744860'
),

joined AS (                                    -- combine proportions with wind
    SELECT
        cc.complaint_type ,
        cc.d ,
        cc.complaint_count ,
        dt.total_count ,
        cc.complaint_count / dt.total_count::FLOAT AS proportion ,
        gj.wind_speed
    FROM complaint_counts cc
    JOIN daily_totals dt ON cc.d = dt.d
    JOIN gsod_jfk     gj ON cc.d = gj.d
    WHERE gj.wind_speed < 999                       -- exclude sentinel values
),

type_totals AS (                               -- keep complaint types > 3 000
    SELECT complaint_type , SUM(complaint_count) AS total_requests
    FROM joined
    GROUP BY complaint_type
    HAVING total_requests > 3000
),

corrs AS (                                     -- Pearson correlations
    SELECT
        j.complaint_type ,
        CORR(j.proportion , j.wind_speed) AS corr
    FROM joined j
    JOIN type_totals t
      ON j.complaint_type = t.complaint_type
    GROUP BY j.complaint_type
)

SELECT
    complaint_type ,
    ROUND(corr , 4) AS correlation
FROM (
    SELECT
        complaint_type ,
        corr ,
        RANK() OVER (ORDER BY corr DESC) AS pos_rank ,
        RANK() OVER (ORDER BY corr ASC)  AS neg_rank
    FROM corrs
)
WHERE pos_rank = 1   -- strongest positive
   OR neg_rank = 1   -- strongest negative
ORDER BY correlation DESC NULLS LAST;