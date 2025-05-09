WITH stats AS (
    /* overall average and standard deviation of loss rates */
    SELECT 
        AVG("loss_rate_%")      AS avg_loss_rate,
        STDDEV_SAMP("loss_rate_%") AS sd_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
),
categorized AS (
    /* tag every item as below, within, or above one standard deviation */
    SELECT 
        CASE 
            WHEN v."loss_rate_%" < s.avg_loss_rate - s.sd_loss_rate THEN 'Below 1 SD'
            WHEN v."loss_rate_%" > s.avg_loss_rate + s.sd_loss_rate THEN 'Above 1 SD'
            ELSE 'Within 1 SD'
        END AS category
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v
    CROSS JOIN stats s
),
summary AS (
    /* count items in each category */
    SELECT
        COUNT_IF(category = 'Below 1 SD')   AS items_below_1sd,
        COUNT_IF(category = 'Within 1 SD')  AS items_within_1sd,
        COUNT_IF(category = 'Above 1 SD')   AS items_above_1sd
    FROM categorized
)
SELECT
    ROUND(s.avg_loss_rate, 4)  AS avg_loss_rate_pct,
    ROUND(s.sd_loss_rate, 4)   AS std_dev_loss_rate_pct,
    su.items_below_1sd,
    su.items_within_1sd,
    su.items_above_1sd
FROM stats s
CROSS JOIN summary su;