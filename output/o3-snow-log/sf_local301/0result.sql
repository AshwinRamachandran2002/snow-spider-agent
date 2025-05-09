/* 1. Aggregate total sales for every Monday-week in each year           */
/* 2. Pick the 4 weeks BEFORE (latest→earliest) and AFTER (earliest→latest) June-15 */
/* 3. Sum the two buckets and calculate the percentage change            */
WITH weekly_totals AS (      /* total company sales per week             */
    SELECT
        "calendar_year"           AS "year",
        TO_DATE("week_date")      AS "week_date",
        SUM("sales")              AS "sales"
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
    WHERE "calendar_year" IN (2018, 2019, 2020)
    GROUP BY "calendar_year", "week_date"
),

before_weeks AS (            /* 4 weeks leading up to 15-June (exclusive) */
    SELECT
        "year",
        "week_date",
        "sales",
        ROW_NUMBER() OVER (
            PARTITION BY "year"
            ORDER BY "week_date" DESC      /* closest weeks first        */
        ) AS rn
    FROM weekly_totals
    WHERE "week_date" < DATE_FROM_PARTS("year", 6, 15)
),

after_weeks AS (             /* 4 weeks following 15-June (exclusive)     */
    SELECT
        "year",
        "week_date",
        "sales",
        ROW_NUMBER() OVER (
            PARTITION BY "year"
            ORDER BY "week_date" ASC       /* earliest weeks first       */
        ) AS rn
    FROM weekly_totals
    WHERE "week_date" > DATE_FROM_PARTS("year", 6, 15)
),

before4 AS (
    SELECT "year",
           SUM("sales") AS sales_before
    FROM before_weeks
    WHERE rn <= 4
    GROUP BY "year"
),

after4 AS (
    SELECT "year",
           SUM("sales") AS sales_after
    FROM after_weeks
    WHERE rn <= 4
    GROUP BY "year"
)

SELECT
    b."year",
    b.sales_before,
    a.sales_after,
    /* % change = (after − before)/before × 100                          */
    (a.sales_after - b.sales_before) / b.sales_before * 100  AS pct_change
FROM before4 b
JOIN after4  a USING ("year")
ORDER BY b."year";