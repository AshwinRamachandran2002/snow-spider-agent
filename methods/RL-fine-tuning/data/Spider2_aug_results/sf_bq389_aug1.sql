-- Task: Please calculate the monthly average levels of PM10 and PM2.5 FRM air pollutants in California for the year 2020.
WITH
Months AS (
    SELECT '01' AS Month_num
    UNION ALL SELECT '02'
    UNION ALL SELECT '03'
    UNION ALL SELECT '04'
    UNION ALL SELECT '05'
    UNION ALL SELECT '06'
    UNION ALL SELECT '07'
    UNION ALL SELECT '08'
    UNION ALL SELECT '09'
    UNION ALL SELECT '10'
    UNION ALL SELECT '11'
    UNION ALL SELECT '12'
),
PM10_AVG AS (
    SELECT
        TO_CHAR("date_local", 'MM') AS Month_num,
        AVG("arithmetic_mean") AS PM10
    FROM
        "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."PM10_DAILY_SUMMARY"
    WHERE
        "state_name" = 'California'
        AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY
        Month_num
),
PM25_FRM_AVG AS (
    SELECT
        TO_CHAR("date_local", 'MM') AS Month_num,
        AVG("arithmetic_mean") AS PM2_5_FRM
    FROM
        "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."PM25_FRM_DAILY_SUMMARY"
    WHERE
        "state_name" = 'California'
        AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
    GROUP BY
        Month_num
)
SELECT
    Months.Month_num,
    TO_CHAR(TO_DATE(Months.Month_num, 'MM'), 'Mon') AS Month,
    ROUND(PM10_AVG.PM10, 4) AS PM10,
    ROUND(PM25_FRM_AVG.PM2_5_FRM, 4) AS PM2_5_FRM
FROM
    Months
    LEFT JOIN PM10_AVG ON Months.Month_num = PM10_AVG.Month_num
    LEFT JOIN PM25_FRM_AVG ON Months.Month_num = PM25_FRM_AVG.Month_num
ORDER BY
    Months.Month_num;