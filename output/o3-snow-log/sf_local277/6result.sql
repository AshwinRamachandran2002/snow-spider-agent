/*----------------------------------------------------------------
  Forecasted average annual sales (2018) for products 4160 & 7790
  – First 36 months of data (Jan-2016 … Dec-2018)
  – Seasonality from time-steps 7 … 30
  – Weighted (idx) linear-trend regression
  – Guard EVERY division with NULLIF(…,0) to avoid 0-division
----------------------------------------------------------------*/
WITH base AS (                          /* first 36 months        */
    SELECT
        "product_id",
        TO_DATE("mth",'YYYY-MM-DD')                 AS mth_date,
        "qty"
    FROM ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
    WHERE "product_id" IN (4160, 7790)
      AND TO_DATE("mth",'YYYY-MM-DD')
            BETWEEN '2016-01-01' AND '2018-12-31'
),
idx_tbl AS (                           /* add month index         */
    SELECT
        "product_id",
        mth_date,
        "qty",
        ROW_NUMBER() OVER (PARTITION BY "product_id"
                           ORDER BY mth_date)       AS idx,
        EXTRACT(month FROM mth_date)                AS month_no
    FROM base
),
cma_tbl AS (                           /* overlapping 12-mo avgs  */
    SELECT
        t.*,
        AVG("qty") OVER (PARTITION BY "product_id"
                         ORDER BY idx
                         ROWS BETWEEN 5 PRECEDING AND 6 FOLLOWING) AS ma1,
        AVG("qty") OVER (PARTITION BY "product_id"
                         ORDER BY idx
                         ROWS BETWEEN 6 PRECEDING AND 5 FOLLOWING) AS ma2
    FROM idx_tbl t
),
ratio_tbl AS (                         /* CMA & sales/CMA ratio   */
    SELECT
        "product_id",
        mth_date,
        "qty",
        idx,
        month_no,
        (ma1 + ma2) / 2                                   AS cma_qty,
        /* protect divide-by-zero when CMA = 0 */
        "qty" / NULLIF( (ma1 + ma2) / 2 , 0)              AS sales_to_cma
    FROM cma_tbl
    WHERE (ma1 + ma2) IS NOT NULL
),
season_tbl AS (                        /* seasonal indices        */
    SELECT
        "product_id",
        month_no,
        AVG(sales_to_cma)                              AS season_idx
    FROM ratio_tbl
    WHERE idx BETWEEN 7 AND 30
      AND sales_to_cma IS NOT NULL
    GROUP BY "product_id", month_no
    HAVING AVG(sales_to_cma) <> 0          /* avoid zero season  */
),
deseason_tbl AS (                      /* de-seasonalised series  */
    SELECT
        r.*,
        s.season_idx,
        r."qty" / NULLIF(s.season_idx,0)                AS deseason_qty
    FROM ratio_tbl r
    JOIN season_tbl s
      ON s."product_id" = r."product_id"
     AND s.month_no      = r.month_no
    WHERE idx <= 36
      AND s.season_idx IS NOT NULL
),
trend_params AS (                      /* weighted regression     */
    SELECT
        "product_id",
        SUM(idx)                           AS sw,
        SUM(idx*idx)                       AS swx,
        SUM(idx*idx*deseason_qty)          AS swxy,
        SUM(idx*idx*idx)                   AS swxx,
        SUM(idx*deseason_qty)              AS swy
    FROM deseason_tbl
    GROUP BY "product_id"
),
forecast_2018 AS (                     /* monthly forecasts 2018  */
    SELECT
        d."product_id",
        d.idx,
        d.season_idx,
        /* denominator for slope/intercept */
        NULLIF(tp.sw * tp.swxx - tp.swx * tp.swx ,0)     AS denom,
        ((tp.sw  * tp.swxy) - (tp.swx * tp.swy))
            / NULLIF(tp.sw * tp.swxx - tp.swx * tp.swx,0) AS slope,
        ((tp.swy * tp.swxx) - (tp.swx * tp.swxy))
            / NULLIF(tp.sw * tp.swxx - tp.swx * tp.swx,0) AS intercept
    FROM deseason_tbl d
    JOIN trend_params tp
      ON tp."product_id" = d."product_id"
    WHERE d.idx BETWEEN 25 AND 36
      AND d.season_idx IS NOT NULL
),
final_months AS (                      /* reseasonalised qty      */
    SELECT
        "product_id",
        idx,
        (slope * idx + intercept) * season_idx           AS forecast_qty
    FROM forecast_2018
    WHERE denom IS NOT NULL
      AND slope IS NOT NULL
      AND intercept IS NOT NULL
),
annual_totals AS (
    SELECT
        "product_id",
        SUM(forecast_qty) AS total_2018
    FROM final_months
    GROUP BY "product_id"
)
SELECT
    AVG(total_2018) AS "AVG_FORECASTED_ANNUAL_SALES_2018"
FROM annual_totals;