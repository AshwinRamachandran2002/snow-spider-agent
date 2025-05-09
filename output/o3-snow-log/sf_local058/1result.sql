WITH "PRODUCT_COUNTS" AS (
    SELECT
        dp."segment"                                                AS "SEGMENT",
        fsm."fiscal_year"                                           AS "FISCAL_YEAR",
        COUNT(DISTINCT fsm."product_code")                          AS "UNIQUE_PRODUCTS"
    FROM
        EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY fsm
        JOIN EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT dp
          ON fsm."product_code" = dp."product_code"
    WHERE
        fsm."fiscal_year" IN (2020, 2021)
    GROUP BY
        dp."segment",
        fsm."fiscal_year"
),
"PIVOT_COUNTS" AS (
    SELECT
        "SEGMENT",
        MAX(CASE WHEN "FISCAL_YEAR" = 2020 THEN "UNIQUE_PRODUCTS" END) AS "CNT_2020",
        MAX(CASE WHEN "FISCAL_YEAR" = 2021 THEN "UNIQUE_PRODUCTS" END) AS "CNT_2021"
    FROM
        "PRODUCT_COUNTS"
    GROUP BY
        "SEGMENT"
),
"CALC" AS (
    SELECT
        "SEGMENT",
        "CNT_2020",
        "CNT_2021",
        CASE
            WHEN "CNT_2020" IS NULL OR "CNT_2020" = 0 THEN NULL
            ELSE ROUND( ( "CNT_2021" - "CNT_2020") * 100.0 / "CNT_2020", 4)
        END AS "PCT_INCREASE_2020_TO_2021"
    FROM
        "PIVOT_COUNTS"
)
SELECT
    "SEGMENT",
    "CNT_2020"          AS "UNIQUE_PRODUCT_COUNT_2020",
    "PCT_INCREASE_2020_TO_2021"
FROM
    "CALC"
ORDER BY
    "PCT_INCREASE_2020_TO_2021" DESC NULLS LAST;