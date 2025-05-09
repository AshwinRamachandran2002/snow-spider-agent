WITH stats AS (
    SELECT 
        ROUND(AVG("loss_rate_%"), 4)        AS avg_loss_rate,
        STDDEV_SAMP("loss_rate_%")          AS std_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
),
categorized AS (
    SELECT
        v."item_code",
        v."item_name",
        v."loss_rate_%",
        s.avg_loss_rate,
        s.std_loss_rate,
        CASE
            WHEN v."loss_rate_%" < s.avg_loss_rate - s.std_loss_rate THEN 'below_one_stddev'
            WHEN v."loss_rate_%" > s.avg_loss_rate + s.std_loss_rate THEN 'above_one_stddev'
            ELSE 'within_one_stddev'
        END AS category
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v
    CROSS JOIN stats s
)
SELECT
    (SELECT avg_loss_rate FROM stats)                            AS avg_loss_rate,
    SUM(CASE WHEN category = 'below_one_stddev'  THEN 1 END)     AS count_below_one_stddev,
    SUM(CASE WHEN category = 'within_one_stddev' THEN 1 END)     AS count_within_one_stddev,
    SUM(CASE WHEN category = 'above_one_stddev'  THEN 1 END)     AS count_above_one_stddev
FROM categorized;