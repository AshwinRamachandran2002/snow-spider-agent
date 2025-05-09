WITH stats AS (
    SELECT 
        AVG("loss_rate_%")         AS avg_loss_rate,
        STDDEV_SAMP("loss_rate_%") AS stddev_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
),
classified AS (
    SELECT
        v."item_code",
        v."item_name",
        v."loss_rate_%",
        CASE
            WHEN v."loss_rate_%" < s.avg_loss_rate - s.stddev_loss_rate THEN 'Below 1 StdDev'
            WHEN v."loss_rate_%" > s.avg_loss_rate + s.stddev_loss_rate THEN 'Above 1 StdDev'
            ELSE                                                        'Within 1 StdDev'
        END AS deviation_category
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v
    CROSS JOIN stats s
),
summary_counts AS (
    SELECT
        COUNT_IF(deviation_category = 'Below 1 StdDev')  AS below_one_stddev_count,
        COUNT_IF(deviation_category = 'Within 1 StdDev') AS within_one_stddev_count,
        COUNT_IF(deviation_category = 'Above 1 StdDev')  AS above_one_stddev_count
    FROM classified
)
SELECT
    ROUND(s.avg_loss_rate, 4)      AS average_loss_rate,
    c.below_one_stddev_count,
    c.within_one_stddev_count,
    c.above_one_stddev_count
FROM stats s
CROSS JOIN summary_counts c;