WITH sales_2021 AS (      -- compute 2021 per-liter prices
    SELECT
        "category_name",
        "sale_dollars" / NULLIF("volume_sold_liters",0)             AS price_per_liter
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES"
    WHERE "date" BETWEEN '2021-01-01' AND '2021-12-31'
      AND "sale_dollars"        IS NOT NULL
      AND "volume_sold_liters"  IS NOT NULL
      AND "volume_sold_liters" <> 0
),
avg_2021 AS (              -- average 2021 prices per category
    SELECT
        "category_name",
        AVG(price_per_liter)                                  AS avg_price_2021
    FROM sales_2021
    GROUP BY "category_name"
),
top10 AS (                 -- pick the 10 highest-priced categories
    SELECT
        "category_name"
    FROM avg_2021
    ORDER BY avg_price_2021 DESC NULLS LAST
    LIMIT 10
),
all_years AS (             -- 2019-2021 per-liter prices for those categories
    SELECT
        "category_name",
        CASE
            WHEN "date" BETWEEN '2019-01-01' AND '2019-12-31' THEN 2019
            WHEN "date" BETWEEN '2020-01-01' AND '2020-12-31' THEN 2020
            WHEN "date" BETWEEN '2021-01-01' AND '2021-12-31' THEN 2021
        END                                                    AS yr,
        "sale_dollars" / NULLIF("volume_sold_liters",0)        AS price_per_liter
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES"
    WHERE "date" BETWEEN '2019-01-01' AND '2021-12-31'
      AND "sale_dollars"        IS NOT NULL
      AND "volume_sold_liters"  IS NOT NULL
      AND "volume_sold_liters" <> 0
      AND "category_name" IN (SELECT "category_name" FROM top10)
),
avg_by_year AS (           -- average per-liter price by category & year
    SELECT
        "category_name",
        yr                                                     AS year,
        AVG(price_per_liter)                                   AS avg_price_per_liter
    FROM all_years
    GROUP BY "category_name", yr
)
SELECT
    "category_name",
    MAX(CASE WHEN year = 2019 THEN avg_price_per_liter END)    AS avg_price_per_liter_2019,
    MAX(CASE WHEN year = 2020 THEN avg_price_per_liter END)    AS avg_price_per_liter_2020,
    MAX(CASE WHEN year = 2021 THEN avg_price_per_liter END)    AS avg_price_per_liter_2021
FROM avg_by_year
GROUP BY "category_name"
ORDER BY avg_price_per_liter_2021 DESC NULLS LAST;