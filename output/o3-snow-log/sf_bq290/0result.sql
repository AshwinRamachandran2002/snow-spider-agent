WITH daily_country AS (  
    SELECT  
        DATE_FROM_PARTS( TO_NUMBER(g."year") , TO_NUMBER(g."mo") , TO_NUMBER(g."da") ) AS "DATE",  
        s."country"                                                                  AS COUNTRY,  
        MAX(g."max")                                                                 AS COUNTRY_MAX,  
        MIN(g."min")                                                                 AS COUNTRY_MIN,  
        AVG(g."temp")                                                                AS COUNTRY_AVG  
    FROM NOAA_DATA.NOAA_GSOD."GSOD2023" g  
    JOIN NOAA_DATA.NOAA_GSOD."STATIONS" s  
      ON g."stn"  = s."usaf"  
     AND g."wban" = s."wban"  
    WHERE g."year" = '2023'  
      AND g."mo"   = '10'      -- October 2023  
      AND g."max"  IS NOT NULL AND g."max"  < 9000  
      AND g."min"  IS NOT NULL AND g."min"  < 9000  
      AND g."temp" IS NOT NULL AND g."temp" < 9000  
      AND s."country" IN ('US','UK')  
    GROUP BY "DATE", COUNTRY  
),  
pivoted AS (  
    SELECT  
        "DATE",  
        MAX(CASE WHEN COUNTRY = 'US' THEN COUNTRY_MAX END) AS US_MAX,  
        MAX(CASE WHEN COUNTRY = 'UK' THEN COUNTRY_MAX END) AS UK_MAX,  
        MAX(CASE WHEN COUNTRY = 'US' THEN COUNTRY_MIN END) AS US_MIN,  
        MAX(CASE WHEN COUNTRY = 'UK' THEN COUNTRY_MIN END) AS UK_MIN,  
        MAX(CASE WHEN COUNTRY = 'US' THEN COUNTRY_AVG END) AS US_AVG,  
        MAX(CASE WHEN COUNTRY = 'UK' THEN COUNTRY_AVG END) AS UK_AVG  
    FROM daily_country  
    GROUP BY "DATE"  
)  
SELECT  
    "DATE",  
    US_MAX - UK_MAX AS MAX_TEMP_DIFF,  
    US_MIN - UK_MIN AS MIN_TEMP_DIFF,  
    US_AVG - UK_AVG AS AVG_TEMP_DIFF  
FROM pivoted  
WHERE US_MAX IS NOT NULL  
  AND UK_MAX IS NOT NULL  
  AND US_MIN IS NOT NULL  
  AND UK_MIN IS NOT NULL  
  AND US_AVG IS NOT NULL  
  AND UK_AVG IS NOT NULL  
ORDER BY "DATE";