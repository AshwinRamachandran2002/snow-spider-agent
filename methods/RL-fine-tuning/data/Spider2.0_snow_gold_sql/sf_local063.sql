WITH city_sales AS (
    SELECT 
        C."cust_city",
        T."calendar_quarter_id",
        SUM(S."amount_sold") AS total_sales
    FROM 
        COMPLEX_ORACLE.COMPLEX_ORACLE.SALES S
    JOIN 
        COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS C ON S."cust_id" = C."cust_id"
    JOIN 
        COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES CT ON C."country_id" = CT."country_id"
    JOIN 
        COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES T ON S."time_id" = T."time_id"
    WHERE 
        CT."country_name" LIKE '%United States%'
        AND S."promo_id" = 999
        AND T."calendar_quarter_id" IN (1772, 1776)
    GROUP BY 
        C."cust_city",
        T."calendar_quarter_id"
),
cities_with_increase AS (
    SELECT
        "cust_city"
    FROM (
        SELECT
            "cust_city",
            SUM(CASE WHEN "calendar_quarter_id" = 1772 THEN total_sales ELSE 0 END) AS sales_2019_Q4,
            SUM(CASE WHEN "calendar_quarter_id" = 1776 THEN total_sales ELSE 0 END) AS sales_2020_Q4
        FROM
            city_sales
        GROUP BY
            "cust_city"
    )
    WHERE
        sales_2019_Q4 > 0
        AND sales_2020_Q4 >= sales_2019_Q4 * 1.2
),
product_sales AS (
    SELECT 
        S."prod_id",
        T."calendar_quarter_id",
        SUM(S."amount_sold") AS product_total_sales
    FROM 
        COMPLEX_ORACLE.COMPLEX_ORACLE.SALES S
    JOIN 
        COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS C ON S."cust_id" = C."cust_id"
    JOIN 
        COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES T ON S."time_id" = T."time_id"
    WHERE 
        S."promo_id" = 999
        AND T."calendar_quarter_id" IN (1772, 1776)
        AND C."cust_city" IN (SELECT "cust_city" FROM cities_with_increase)
    GROUP BY 
        S."prod_id",
        T."calendar_quarter_id"
),
total_sales AS (
    SELECT
        T."calendar_quarter_id",
        SUM(S."amount_sold") AS total_sales_amount
    FROM 
        COMPLEX_ORACLE.COMPLEX_ORACLE.SALES S
    JOIN 
        COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS C ON S."cust_id" = C."cust_id"
    JOIN 
        COMPLEX_ORACLE.COMPLEX_ORACLE.TIMES T ON S."time_id" = T."time_id"
    WHERE 
        S."promo_id" = 999
        AND T."calendar_quarter_id" IN (1772, 1776)
        AND C."cust_city" IN (SELECT "cust_city" FROM cities_with_increase)
    GROUP BY 
        T."calendar_quarter_id"
),
product_shares AS (
    SELECT
        ps."prod_id",
        ps."calendar_quarter_id",
        ps.product_total_sales,
        ts.total_sales_amount,
        ps.product_total_sales / NULLIF(ts.total_sales_amount, 0) AS product_share
    FROM
        product_sales ps
    JOIN
        total_sales ts ON ps."calendar_quarter_id" = ts."calendar_quarter_id"
),
product_share_changes AS (
    SELECT
        "prod_id",
        SUM(CASE WHEN "calendar_quarter_id" = 1772 THEN product_share ELSE 0 END) AS share_2019_Q4,
        SUM(CASE WHEN "calendar_quarter_id" = 1776 THEN product_share ELSE 0 END) AS share_2020_Q4
    FROM
        product_shares
    GROUP BY
        "prod_id"
),
product_percentage_point_change AS (
    SELECT
        psc."prod_id",
        psc.share_2019_Q4,
        psc.share_2020_Q4,
        psc.share_2020_Q4 - psc.share_2019_Q4 AS percentage_point_change
    FROM
        product_share_changes psc
),
product_totals AS (
    SELECT
        "prod_id",
        SUM("amount_sold") AS total_sales
    FROM
        COMPLEX_ORACLE.COMPLEX_ORACLE.SALES
    GROUP BY
        "prod_id"
),
product_totals_ranked AS (
    SELECT
        "prod_id",
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC NULLS LAST) AS sales_rank,
        COUNT(*) OVER () AS total_products
    FROM
        product_totals
),
product_top_20_percent AS (
    SELECT
        "prod_id",
        total_sales
    FROM
        product_totals_ranked
    WHERE
        sales_rank <= CEIL(total_products * 0.2)
),
final_product_changes AS (
    SELECT
        pppc."prod_id",
        pppc.share_2019_Q4,
        pppc.share_2020_Q4,
        pppc.percentage_point_change
    FROM
        product_percentage_point_change pppc
    INNER JOIN
        product_top_20_percent ptp ON pppc."prod_id" = ptp."prod_id"
    WHERE
        pppc.percentage_point_change IS NOT NULL
)
SELECT
    p."prod_id" AS product_id,
    pr."prod_name" AS product_name,
    ROUND(p.percentage_point_change, 4) AS percentage_point_change
FROM
    final_product_changes p
JOIN
    COMPLEX_ORACLE.COMPLEX_ORACLE.PRODUCTS pr ON p."prod_id" = pr."prod_id"
ORDER BY
    ABS(p.percentage_point_change) ASC NULLS LAST
LIMIT 1;