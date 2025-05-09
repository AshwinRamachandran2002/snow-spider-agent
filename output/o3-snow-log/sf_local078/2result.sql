/*  Identify the peak-composition month for every interest category,
    then return the 10 highest and 10 lowest such peaks               */

WITH ranked AS (
    SELECT
        m."interest_id",
        m."month_year",
        m."composition",
        ROW_NUMBER() OVER (
            PARTITION BY m."interest_id"
            ORDER BY m."composition" DESC,
                     m."_year" ASC,
                     m."_month" ASC
        ) AS rn
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS" m
),

per_interest_max AS (          -- highest-composition row per category
    SELECT
        r."interest_id",
        r."month_year" AS "time_MM_YYYY",
        r."composition"
    FROM ranked r
    WHERE r.rn = 1
),

per_interest_details AS (      -- add category name
    SELECT
        p."time_MM_YYYY",
        i."interest_name",
        p."composition"
    FROM per_interest_max p
    LEFT JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP" i
           ON CAST(p."interest_id" AS NUMBER) = i."id"
),

top10 AS (                     -- 10 largest compositions
    SELECT
        'TOP' AS "bucket",
        d."time_MM_YYYY",
        d."interest_name",
        d."composition"
    FROM per_interest_details d
    ORDER BY d."composition" DESC NULLS LAST
    LIMIT 10
),

bottom10 AS (                  -- 10 smallest compositions
    SELECT
        'BOTTOM' AS "bucket",
        d."time_MM_YYYY",
        d."interest_name",
        d."composition"
    FROM per_interest_details d
    ORDER BY d."composition" ASC NULLS LAST
    LIMIT 10
)

SELECT * FROM top10
UNION ALL
SELECT * FROM bottom10;