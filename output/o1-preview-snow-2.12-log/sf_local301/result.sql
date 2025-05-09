WITH jun15_weeks AS (
    SELECT
        "calendar_year",
        DATE_TRUNC('WEEK', TO_DATE("calendar_year" || '-06-15', 'YYYY-MM-DD')) AS jun15_week_start
    FROM
        (
            SELECT DISTINCT "calendar_year"
            FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
            WHERE "calendar_year" IN (2018, 2019, 2020)
        )
)
SELECT
    s."calendar_year" AS "Year",
    ROUND(((s.post_sales - s.pre_sales) / NULLIF(s.pre_sales, 0)) * 100, 4) AS "Percentage_Change"
FROM
    (
        SELECT
            s."calendar_year",
            SUM(
                CASE
                    WHEN TO_DATE(s."week_date", 'YYYY-MM-DD') >= DATEADD(week, -4, j.jun15_week_start)
                         AND TO_DATE(s."week_date", 'YYYY-MM-DD') < j.jun15_week_start
                    THEN s."sales"
                    ELSE 0
                END
            ) AS pre_sales,
            SUM(
                CASE
                    WHEN TO_DATE(s."week_date", 'YYYY-MM-DD') > j.jun15_week_start
                         AND TO_DATE(s."week_date", 'YYYY-MM-DD') <= DATEADD(week, 4, j.jun15_week_start)
                    THEN s."sales"
                    ELSE 0
                END
            ) AS post_sales
        FROM
            BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES s
            JOIN jun15_weeks j ON s."calendar_year" = j."calendar_year"
        WHERE
            s."calendar_year" IN (2018, 2019, 2020)
            AND TO_DATE(s."week_date", 'YYYY-MM-DD') BETWEEN DATEADD(week, -4, j.jun15_week_start) AND DATEADD(week, 4, j.jun15_week_start)
        GROUP BY
            s."calendar_year"
    ) s
ORDER BY
    "Year";