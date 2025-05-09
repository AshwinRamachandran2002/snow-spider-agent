/* ---------------------------------------------------------
   Forecast 2018 average annual sales for products 4160 & 7790
   --------------------------------------------------------- */
WITH sales_raw AS (   /* 1. Load monthly sales from Jan-2016 */
    SELECT
        "product_id"                         AS PRODUCT_ID,
        TO_DATE("mth")                       AS MTH_DATE,
        "qty"                                AS QTY
    FROM ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
    WHERE "product_id" IN (4160, 7790)
      AND TO_DATE("mth") >= '2016-01-01'
),

sales36 AS (          /* 2. Keep first 36 consecutive months */
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY PRODUCT_ID
                           ORDER BY MTH_DATE)           AS MONTH_NO
    FROM sales_raw s
    QUALIFY MONTH_NO <= 36
),

cma_calc AS (         /* 3. Centered Moving Average (CMA)  */
    SELECT
        s.*,
        (
            /* window: 5 before + 6 after */
            ( SELECT AVG(z.QTY)
              FROM sales36 z
              WHERE z.PRODUCT_ID = s.PRODUCT_ID
                AND z.MONTH_NO BETWEEN s.MONTH_NO-5 AND s.MONTH_NO+6 )
            +
            /* window: 6 before + 5 after */
            ( SELECT AVG(z.QTY)
              FROM sales36 z
              WHERE z.PRODUCT_ID = s.PRODUCT_ID
                AND z.MONTH_NO BETWEEN s.MONTH_NO-6 AND s.MONTH_NO+5 )
        ) / 2                                        AS CMA
    FROM sales36 s
),

ratio AS (            /* 4. Sales-to-CMA ratio */
    SELECT
        *,
        CASE WHEN CMA IS NOT NULL AND CMA <> 0
             THEN QTY / CMA END                      AS RATIO
    FROM cma_calc
),

seasonality AS (      /* 5. Seasonal factors (months 7-30) */
    SELECT
        PRODUCT_ID,
        EXTRACT(month FROM MTH_DATE)                 AS MONTH_IDX,
        AVG(RATIO)                                   AS SEASON_FACTOR
    FROM ratio
    WHERE MONTH_NO BETWEEN 7 AND 30
      AND RATIO IS NOT NULL
    GROUP BY PRODUCT_ID, MONTH_IDX
),

weighted_stats AS (   /* 6. Stats for weighted regression   */
    SELECT
        PRODUCT_ID,
        SUM(CMA)                       AS SW,
        SUM(CMA*MONTH_NO)              AS SWX,
        SUM(CMA*QTY)                   AS SWY,
        SUM(CMA*POWER(MONTH_NO,2))     AS SWXX,
        SUM(CMA*MONTH_NO*QTY)          AS SWXY
    FROM cma_calc
    WHERE CMA IS NOT NULL
    GROUP BY PRODUCT_ID
),

trend_params AS (     /* 7. Regression coefficients         */
    SELECT
        PRODUCT_ID,
        (SW*SWXY - SWX*SWY) /
        (SW*SWXX - POWER(SWX,2))                      AS SLOPE,
        (SWY - ((SW*SWXY - SWX*SWY) /
                (SW*SWXX - POWER(SWX,2))) * SWX) / SW AS INTERCEPT
    FROM weighted_stats
),

forecast_2018 AS (    /* 8. Trend × Seasonality (months 25-36) */
    SELECT
        s.PRODUCT_ID,
        s.MONTH_NO,
        s.MTH_DATE,
        tp.INTERCEPT + tp.SLOPE * s.MONTH_NO          AS TREND_COMPONENT,
        se.SEASON_FACTOR,
        (tp.INTERCEPT + tp.SLOPE * s.MONTH_NO)
          * se.SEASON_FACTOR                          AS FORECAST_QTY
    FROM sales36       s
    JOIN trend_params  tp ON tp.PRODUCT_ID = s.PRODUCT_ID
    JOIN seasonality   se ON se.PRODUCT_ID = s.PRODUCT_ID
                         AND se.MONTH_IDX = EXTRACT(month FROM s.MTH_DATE)
    WHERE s.MONTH_NO BETWEEN 25 AND 36               /* calendar 2018 */
),

annual_per_product AS ( /* 9. Annual total per product */
    SELECT
        PRODUCT_ID,
        SUM(FORECAST_QTY) AS ANNUAL_FORECAST_QTY
    FROM forecast_2018
    GROUP BY PRODUCT_ID
),

average_annual AS (    /* 10. Final average across products */
    SELECT
        AVG(ANNUAL_FORECAST_QTY) AS AVG_FORECASTED_ANNUAL_SALES_2018
    FROM annual_per_product
)

/* ---------------------------------------------------------
   Result
   --------------------------------------------------------- */
SELECT *
FROM average_annual;