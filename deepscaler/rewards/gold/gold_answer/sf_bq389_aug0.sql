-- Task: Calculate the monthly average levels of PM10, PM2.5 FRM, PM2.5 non-FRM, volatile organic compounds (VOC), sulfur dioxide (SO2), and lead air pollutants in California for the year 2020, using data from their respective daily summary tables. For SO2 and lead, scale the average levels by multiplying by 10 and 100, respectively. Include the month number and the abbreviated month name in the results. Round the average levels to four decimal places. Ensure that all months from January to December are included in the output, even if data for some pollutants are missing in certain months.

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
    ),
    PM25_NONFRM_AVG AS (
        SELECT
            TO_CHAR("date_local", 'MM') AS Month_num,
            AVG("arithmetic_mean") AS PM2_5_NON_FRM
        FROM
            "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."PM25_NONFRM_DAILY_SUMMARY"
        WHERE
            "state_name" = 'California'
            AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
        GROUP BY
            Month_num
    ),
    VOC_AVG AS (
        SELECT
            TO_CHAR("date_local", 'MM') AS Month_num,
            AVG("arithmetic_mean") AS VOC
        FROM
            "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."VOC_DAILY_SUMMARY"
        WHERE
            "state_name" = 'California'
            AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
        GROUP BY
            Month_num
    ),
    SO2_AVG AS (
        SELECT
            TO_CHAR("date_local", 'MM') AS Month_num,
            AVG("arithmetic_mean") * 10 AS SO2_SCALED
        FROM
            "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."SO2_DAILY_SUMMARY"
        WHERE
            "state_name" = 'California'
            AND "date_local" BETWEEN '2020-01-01' AND '2020-12-31'
        GROUP BY
            Month_num
    ),
    Lead_AVG AS (
        SELECT
            TO_CHAR("date_local", 'MM') AS Month_num,
            AVG("arithmetic_mean") * 100 AS Lead_SCALED
        FROM
            "EPA_HISTORICAL_AIR_QUALITY"."EPA_HISTORICAL_AIR_QUALITY"."LEAD_DAILY_SUMMARY"
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
    ROUND(PM25_FRM_AVG.PM2_5_FRM, 4) AS PM2_5_FRM,
    ROUND(PM25_NONFRM_AVG.PM2_5_NON_FRM, 4) AS PM2_5_NON_FRM,
    ROUND(VOC_AVG.VOC, 4) AS VOC,
    ROUND(SO2_AVG.SO2_SCALED, 4) AS SO2_SCALED,
    ROUND(Lead_AVG.Lead_SCALED, 4) AS Lead_SCALED
FROM
    Months
    LEFT JOIN PM10_AVG ON Months.Month_num = PM10_AVG.Month_num
    LEFT JOIN PM25_FRM_AVG ON Months.Month_num = PM25_FRM_AVG.Month_num
    LEFT JOIN PM25_NONFRM_AVG ON Months.Month_num = PM25_NONFRM_AVG.Month_num
    LEFT JOIN VOC_AVG ON Months.Month_num = VOC_AVG.Month_num
    LEFT JOIN SO2_AVG ON Months.Month_num = SO2_AVG.Month_num
    LEFT JOIN Lead_AVG ON Months.Month_num = Lead_AVG.Month_num
ORDER BY
    Months.Month_num;