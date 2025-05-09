WITH
-- distinct products that had sales in 2020
sales_2020 AS (
    SELECT DISTINCT "product_code"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY
    WHERE "fiscal_year" = 2020
),
-- distinct products that had sales in 2021
sales_2021 AS (
    SELECT DISTINCT "product_code"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_FACT_SALES_MONTHLY
    WHERE "fiscal_year" = 2021
),
-- map every product to its segment
prod_segment AS (
    SELECT "product_code", "segment"
    FROM EDUCATION_BUSINESS.EDUCATION_BUSINESS.HARDWARE_DIM_PRODUCT
),
-- unique-product counts per segment for 2020
segment_2020 AS (
    SELECT ps."segment",
           COUNT(DISTINCT s20."product_code") AS prod_cnt_2020
    FROM sales_2020 s20
    JOIN prod_segment ps ON ps."product_code" = s20."product_code"
    GROUP BY ps."segment"
),
-- unique-product counts per segment for 2021
segment_2021 AS (
    SELECT ps."segment",
           COUNT(DISTINCT s21."product_code") AS prod_cnt_2021
    FROM sales_2021 s21
    JOIN prod_segment ps ON ps."product_code" = s21."product_code"
    GROUP BY ps."segment"
),
-- combine the two years, compute % increase
combined AS (
    SELECT
        COALESCE(s20."segment", s21."segment") AS "segment",
        COALESCE(s20.prod_cnt_2020, 0)          AS prod_cnt_2020,
        COALESCE(s21.prod_cnt_2021, 0)          AS prod_cnt_2021
    FROM segment_2020 s20
    FULL OUTER JOIN segment_2021 s21
        ON s20."segment" = s21."segment"
),
calc AS (
    SELECT
        "segment",
        prod_cnt_2020,
        prod_cnt_2021,
        CASE
            WHEN prod_cnt_2020 = 0 THEN NULL
            ELSE ROUND((prod_cnt_2021 - prod_cnt_2020) * 100.0 / prod_cnt_2020, 4)
        END AS pct_increase
    FROM combined
)
-- final output: segment + 2020 unique-product count,
-- ordered by highest % increase from 2020 to 2021
SELECT
    "segment",
    prod_cnt_2020 AS "unique_product_count_2020"
FROM calc
ORDER BY pct_increase DESC NULLS LAST;