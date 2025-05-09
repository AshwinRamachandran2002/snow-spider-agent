/*  Top 10 and Bottom 10 interest categories
    – based on each category’s single highest “composition” value                */

WITH best_month_per_interest AS (
    /* For every interest, keep the month that delivered its peak composition */
    SELECT
        m."month_year",                     -- time (MM-YYYY)
        i."interest_name",
        m."composition",
        ROW_NUMBER() OVER (
            PARTITION BY m."interest_id"
            ORDER BY m."composition" DESC, m."month_year"
        ) AS rn                              -- 1 = month of highest composition
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_METRICS   m
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING.INTEREST_MAP       i
          ON m."interest_id" = i."id"
)
, top10 AS (
    SELECT
        "month_year",
        "interest_name",
        "composition"
    FROM best_month_per_interest
    WHERE rn = 1
    ORDER BY "composition" DESC NULLS LAST
    LIMIT 10
)
, bottom10 AS (
    SELECT
        "month_year",
        "interest_name",
        "composition"
    FROM best_month_per_interest
    WHERE rn = 1
    ORDER BY "composition" ASC NULLS LAST
    LIMIT 10
)
SELECT 
    "month_year"      AS "TIME(MM-YYYY)",
    "interest_name"   AS "INTEREST_NAME",
    "composition"     AS "COMPOSITION"
FROM top10

UNION ALL

SELECT
    "month_year"      AS "TIME(MM-YYYY)",
    "interest_name"   AS "INTEREST_NAME",
    "composition"     AS "COMPOSITION"
FROM bottom10;