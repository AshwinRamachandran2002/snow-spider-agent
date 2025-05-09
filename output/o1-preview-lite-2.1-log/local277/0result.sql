WITH sales_data AS (
    SELECT "product_id", "mth", "qty",
           ((CAST(strftime('%Y', "mth") AS INTEGER) - 2016) * 12) + (CAST(strftime('%m', "mth") AS INTEGER) - 1) + 1 AS "time_step",
           CASE WHEN ((CAST(strftime('%Y', "mth") AS INTEGER) - 2016) * 12) + (CAST(strftime('%m', "mth") AS INTEGER) - 1) + 1 BETWEEN 7 AND 30
                THEN 3 ELSE 1 END AS w_i
    FROM "monthly_sales"
    WHERE "product_id" IN (4160, 7790)
      AND "mth" BETWEEN '2016-01-01' AND '2018-12-01'
),
aggregated_sums AS (
    SELECT
        "product_id",
        SUM(w_i) AS W,
        SUM(w_i * "time_step") AS Sum_wx,
        SUM(w_i * "time_step" * "time_step") AS Sum_wx2,
        SUM(w_i * "qty") AS Sum_wy,
        SUM(w_i * "time_step" * "qty") AS Sum_wxy
    FROM sales_data
    GROUP BY "product_id"
),
regression_params AS (
    SELECT
        "product_id",
        W,
        Sum_wx,
        Sum_wx2,
        Sum_wy,
        Sum_wxy,
        (Sum_wx * 1.0) / W AS x_bar,
        (Sum_wy * 1.0) / W AS y_bar,
        (Sum_wxy - (Sum_wx * Sum_wy * 1.0) / W) / (Sum_wx2 - (Sum_wx * Sum_wx * 1.0) / W) AS b,
        ((Sum_wy * 1.0) / W) - ((Sum_wxy - (Sum_wx * Sum_wy * 1.0) / W) / (Sum_wx2 - (Sum_wx * Sum_wx * 1.0) / W)) * ((Sum_wx * 1.0) / W) AS a
    FROM aggregated_sums
),
forecast AS (
    SELECT
        r."product_id",
        s."time_step",
        (r.a + r.b * s."time_step") AS forecasted_qty
    FROM regression_params r
    CROSS JOIN (
        SELECT DISTINCT "time_step"
        FROM sales_data
        WHERE "time_step" BETWEEN 25 AND 36
    ) s
)
SELECT "product_id", SUM(forecasted_qty) / 12.0 AS Average_Forecasted_Annual_Sales_2018
FROM forecast
GROUP BY "product_id";