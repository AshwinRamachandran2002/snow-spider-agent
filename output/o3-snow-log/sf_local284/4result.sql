WITH stats AS (
    SELECT 
        ROUND(AVG("loss_rate_%"), 4)      AS avg_loss_rate,
        ROUND(STDDEV_SAMP("loss_rate_%"), 4) AS stddev_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
),
categorized AS (
    SELECT
        d."item_code",
        d."loss_rate_%",
        CASE
            WHEN d."loss_rate_%" < s.avg_loss_rate - s.stddev_loss_rate THEN 'below_one_stddev'
            WHEN d."loss_rate_%" > s.avg_loss_rate + s.stddev_loss_rate THEN 'above_one_stddev'
            ELSE 'within_one_stddev'
        END AS category
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF d
    CROSS JOIN stats s
)
SELECT
    (SELECT avg_loss_rate FROM stats)      AS average_loss_rate,
    (SELECT stddev_loss_rate FROM stats)   AS stddev_loss_rate,
    SUM(CASE WHEN category = 'below_one_stddev'  THEN 1 ELSE 0 END) AS below_one_stddev_count,
    SUM(CASE WHEN category = 'within_one_stddev' THEN 1 ELSE 0 END) AS within_one_stddev_count,
    SUM(CASE WHEN category = 'above_one_stddev'  THEN 1 ELSE 0 END) AS above_one_stddev_count
FROM categorized;