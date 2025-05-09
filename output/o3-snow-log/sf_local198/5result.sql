WITH "countries_with_many_customers" AS (
    SELECT
        "Country"
    FROM CHINOOK.CHINOOK.CUSTOMERS
    GROUP BY "Country"
    HAVING COUNT("CustomerId") > 4
),
"sales_per_country" AS (
    SELECT
        I."BillingCountry"           AS "Country",
        SUM(I."Total")               AS "CountrySales"
    FROM CHINOOK.CHINOOK.INVOICES I
    WHERE I."BillingCountry" IN (SELECT "Country" FROM "countries_with_many_customers")
    GROUP BY I."BillingCountry"
)
SELECT
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "CountrySales"),
        4
    ) AS "MedianCountrySales"
FROM "sales_per_country";