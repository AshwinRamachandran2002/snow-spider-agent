/*--------------------------------------------------------------------
  Forecast average annual sales for products 4160 and 7790 in 2018
  – safe divisions added to avoid “division by zero” errors
--------------------------------------------------------------------*/
WITH base AS (                      /* 1. 36-month raw history            */
    SELECT
        "product_id",
        TO_DATE("mth")                       AS "mth",
        "qty"
    FROM ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
    WHERE "product_id" IN (4160, 7790)
      AND "mth" BETWEEN '2016-01-01' AND '2018-12-01'
),
idx AS (                           /* 2. add running index and month no. */
    SELECT
        "product_id",
        "mth",
        "qty",
        ROW_NUMBER()  OVER (PARTITION BY "product_id" ORDER BY "mth") AS t,
        MONTH("mth")                                                  AS mon
    FROM base
),
cma AS (                           /* 3. 12-month centred moving average */
    SELECT
        i.*,
        (
            AVG("qty") OVER (PARTITION BY "product_id"
                              ORDER BY t
                              ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING)
          + AVG("qty") OVER (PARTITION BY "product_id"
                              ORDER BY t
                              ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING)
        ) / 2                                            AS cma
    FROM idx i
),
ratio AS (                         /* 4. sales-to-CMA ratios (t 7-30)    */
    SELECT
        *,
        CASE 
            WHEN t BETWEEN 7 AND 30 
             AND cma IS NOT NULL 
             AND cma <> 0
            THEN "qty" / cma
        END                                             AS ratio
    FROM cma
),
season_raw AS (                    /* 5. monthly preliminary factors     */
    SELECT
        "product_id",
        mon,
        AVG(ratio)                                   AS avg_ratio
    FROM ratio
    WHERE ratio IS NOT NULL
    GROUP BY "product_id", mon
),
season_adj AS (                    /* 6. rescale factors so mean = 1     */
    SELECT
        s."product_id",
        s.mon,
        s.avg_ratio 
          / NULLIF(
                AVG(s.avg_ratio) OVER (PARTITION BY s."product_id"),
                0
            )                                       AS seas_fac
    FROM season_raw s
),
deseason AS (                      /* 7. de-seasonalised quantities       */
    SELECT
        r."product_id",
        r."mth",
        r.t,
        r."qty",
        sa.seas_fac,
        CASE 
            WHEN sa.seas_fac IS NOT NULL AND sa.seas_fac <> 0
            THEN r."qty" / sa.seas_fac
        END                                         AS de_qty
    FROM ratio       r
    JOIN season_adj  sa
      ON sa."product_id" = r."product_id"
     AND sa.mon        = r.mon
    WHERE r."qty" IS NOT NULL
),
trend AS (                         /* 8. linear regression (trend)        */
    SELECT
        "product_id",
        REGR_SLOPE(de_qty, t)      AS slope,
        REGR_INTERCEPT(de_qty, t)  AS intercept
    FROM deseason
    WHERE de_qty IS NOT NULL
    GROUP BY "product_id"
),
forecast_mth AS (                  /* 9. monthly forecast for 2018        */
    SELECT
        d."product_id",
        d."mth",
        (tr.intercept + tr.slope * d.t) * sa.seas_fac   AS f_qty
    FROM deseason     d
    JOIN trend        tr ON tr."product_id" = d."product_id"
    JOIN season_adj   sa ON sa."product_id" = d."product_id"
                        AND sa.mon = MONTH(d."mth")
    WHERE d."mth" BETWEEN '2018-01-01' AND '2018-12-01'
      AND sa.seas_fac IS NOT NULL
      AND tr.intercept IS NOT NULL 
      AND tr.slope     IS NOT NULL
),
annual_fcast AS (                  /* 10. annual total per product        */
    SELECT
        "product_id",
        SUM(f_qty)  AS forecast_2018
    FROM forecast_mth
    GROUP BY "product_id"
)
SELECT AVG(forecast_2018) AS avg_forecast_2018
FROM   annual_fcast;