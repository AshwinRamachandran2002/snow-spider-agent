WITH SalesData AS (
    SELECT 
        "product_id",
        "mth",
        "qty",
        DATEDIFF(month, TO_DATE('2016-01-01','YYYY-MM-DD'), TO_DATE("mth",'YYYY-MM-DD')) + 1 AS "t",
        EXTRACT(month FROM TO_DATE("mth", 'YYYY-MM-DD')) AS "month_num"
    FROM ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
    WHERE "product_id" IN (4160, 7790)
        AND TO_DATE("mth", 'YYYY-MM-DD') >= TO_DATE('2016-01-01','YYYY-MM-DD')
        AND TO_DATE("mth", 'YYYY-MM-DD') <= TO_DATE('2018-12-01','YYYY-MM-DD')
),
SeasonalFactors AS (
    SELECT
        "product_id",
        "month_num",
        AVG("qty") AS "avg_qty"
    FROM SalesData
    WHERE "t" BETWEEN 7 AND 30
    GROUP BY "product_id", "month_num"
),
TotalAverage AS (
    SELECT
        "product_id",
        AVG("qty") AS "total_avg_qty"
    FROM SalesData
    WHERE "t" BETWEEN 7 AND 30
    GROUP BY "product_id"
),
SeasonalIndices AS (
    SELECT
        sf."product_id",
        sf."month_num",
        sf."avg_qty" / NULLIF(ta."total_avg_qty", 0) AS "seasonal_index"
    FROM SeasonalFactors sf
    JOIN TotalAverage ta ON sf."product_id" = ta."product_id"
),
AdjustedSales AS (
    SELECT
        sd."product_id",
        sd."t",
        sd."qty",
        sd."month_num",
        si."seasonal_index",
        sd."qty" / NULLIF(si."seasonal_index", 0) AS "adjusted_sales"
    FROM SalesData sd
    JOIN SeasonalIndices si ON sd."product_id" = si."product_id" AND sd."month_num" = si."month_num"
    WHERE sd."t" BETWEEN 7 AND 30
),
AverageAdjustedSales AS (
    SELECT
        "product_id",
        AVG("adjusted_sales") AS "avg_adjusted_sales"
    FROM AdjustedSales
    GROUP BY "product_id"
),
ForecastedSales AS (
    SELECT
        sd."product_id",
        sd."mth",
        sd."t",
        si."seasonal_index",
        aas."avg_adjusted_sales" * si."seasonal_index" AS "forecasted_qty"
    FROM SalesData sd
    JOIN SeasonalIndices si ON sd."product_id" = si."product_id" AND sd."month_num" = si."month_num"
    JOIN AverageAdjustedSales aas ON sd."product_id" = aas."product_id"
    WHERE sd."t" BETWEEN 31 AND 36
)
SELECT
    "product_id" AS "Product_ID",
    ROUND(SUM("forecasted_qty"), 4) AS "Average_Forecasted_Annual_Sales_2018"
FROM ForecastedSales
GROUP BY "product_id";