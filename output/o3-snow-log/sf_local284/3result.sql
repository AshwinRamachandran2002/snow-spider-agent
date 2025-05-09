WITH stats AS (
    SELECT
        AVG("loss_rate_%")         AS avg_loss_rate,
        STDDEV_SAMP("loss_rate_%") AS stddev_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
    WHERE "loss_rate_%" IS NOT NULL
),
classified AS (
    SELECT
        v."item_code",
        v."item_name",
        v."loss_rate_%",
        CASE
            WHEN v."loss_rate_%" < s.avg_loss_rate - s.stddev_loss_rate THEN 'Below'
            WHEN v."loss_rate_%" > s.avg_loss_rate + s.stddev_loss_rate THEN 'Above'
            ELSE 'Within'
        END AS category
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v
    CROSS JOIN stats s
    WHERE v."loss_rate_%" IS NOT NULL
)
SELECT
    ROUND(MAX(s.avg_loss_rate), 4)                                                      AS average_loss_rate,
    SUM(CASE WHEN c.category = 'Below'  THEN 1 ELSE 0 END)                              AS count_below_stddev,
    SUM(CASE WHEN c.category = 'Within' THEN 1 ELSE 0 END)                              AS count_within_stddev,
    SUM(CASE WHEN c.category = 'Above'  THEN 1 ELSE 0 END)                              AS count_above_stddev
FROM classified c
CROSS JOIN stats s;