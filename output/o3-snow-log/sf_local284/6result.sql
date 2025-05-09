WITH stats AS (
    SELECT 
        AVG("loss_rate_%")     AS avg_loss_rate,
        STDDEV_SAMP("loss_rate_%") AS stddev_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
    WHERE "loss_rate_%" IS NOT NULL
),
classified AS (
    SELECT
        SUM(CASE WHEN v."loss_rate_%" <  s.avg_loss_rate - s.stddev_loss_rate THEN 1 ELSE 0 END) AS count_below_one_sd,
        SUM(CASE WHEN v."loss_rate_%" >  s.avg_loss_rate + s.stddev_loss_rate THEN 1 ELSE 0 END) AS count_above_one_sd,
        SUM(CASE WHEN v."loss_rate_%" BETWEEN s.avg_loss_rate - s.stddev_loss_rate 
                                      AND     s.avg_loss_rate + s.stddev_loss_rate THEN 1 ELSE 0 END) AS count_within_one_sd
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v
    CROSS JOIN stats s
    WHERE v."loss_rate_%" IS NOT NULL
)
SELECT 
    s.avg_loss_rate,
    s.stddev_loss_rate,
    c.count_below_one_sd,
    c.count_within_one_sd,
    c.count_above_one_sd
FROM stats s, classified c;