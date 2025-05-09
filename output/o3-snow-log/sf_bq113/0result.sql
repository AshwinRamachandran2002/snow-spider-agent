/*  County in Utah with the greatest % increase in construction employment
    (average of month-3 employment each quarter) from 2000 to 2018          */
WITH y2000 AS (   -- 2000 quarterly averages
    SELECT 
        "area_fips"                                    AS county_fips ,
        AVG("month3_emplvl_1012_construction")         AS avg_2000
    FROM (
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2000_Q1
          UNION ALL
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2000_Q2
          UNION ALL
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2000_Q3
          UNION ALL
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2000_Q4
    )
    WHERE "area_fips" ILIKE '49%'          -- Utah counties
    GROUP BY "area_fips"
),

y2018 AS (   -- 2018 quarterly averages
    SELECT 
        "area_fips"                                    AS county_fips ,
        AVG("month3_emplvl_1012_construction")         AS avg_2018
    FROM (
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2018_Q1
          UNION ALL
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2018_Q2
          UNION ALL
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2018_Q3
          UNION ALL
          SELECT "area_fips","month3_emplvl_1012_construction" FROM BLS.BLS_QCEW._2018_Q4
    )
    WHERE "area_fips" ILIKE '49%'          -- Utah counties
    GROUP BY "area_fips"
)

SELECT
    y18.county_fips                                            AS utah_county_fips ,
    ROUND(
        100.0 * ( y18.avg_2018 - y00.avg_2000 )
              / NULLIF( y00.avg_2000 , 0 ) , 2)                AS pct_increase_2000_to_2018
FROM   y2000 y00
JOIN   y2018 y18 USING ( county_fips )
WHERE  y00.avg_2000 IS NOT NULL
ORDER  BY pct_increase_2000_to_2018 DESC NULLS LAST
LIMIT 1;