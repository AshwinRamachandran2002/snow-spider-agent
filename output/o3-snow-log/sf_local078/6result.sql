WITH ranked AS  (
    SELECT
        im."interest_name",
        me."interest_id",
        me."month_year",
        me."composition",
        ROW_NUMBER() OVER (
            PARTITION BY me."interest_id"
            ORDER BY me."composition" DESC NULLS LAST, me."month_year"
        ) AS rn
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_METRICS"  me
    JOIN BANK_SALES_TRADING.BANK_SALES_TRADING."INTEREST_MAP"      im
      ON CAST(im."id" AS FLOAT) = me."interest_id"
    WHERE me."composition" IS NOT NULL
),
max_comp AS (
    -- one record per interest category (its highest composition and the time it occurred)
    SELECT
        "interest_id",
        "interest_name",
        "month_year",
        "composition"
    FROM ranked
    WHERE rn = 1
),
top_10 AS (
    SELECT
        'TOP' AS rank_group,
        "month_year"          AS time_mm_yyyy,
        "interest_name",
        "composition"
    FROM max_comp
    ORDER BY "composition" DESC NULLS LAST
    LIMIT 10
),
bottom_10 AS (
    SELECT
        'BOTTOM' AS rank_group,
        "month_year"          AS time_mm_yyyy,
        "interest_name",
        "composition"
    FROM max_comp
    ORDER BY "composition" ASC NULLS LAST
    LIMIT 10
)

SELECT *
FROM top_10
UNION ALL
SELECT *
FROM bottom_10;