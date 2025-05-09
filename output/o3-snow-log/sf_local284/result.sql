/*-------------------------------------------------------------
  Summary of vegetable items' loss rates
  1. Calculate overall mean and standard deviation of "loss_rate_%"
  2. Classify every item as BELOW, WITHIN, or ABOVE one std-dev of the mean
  3. Count items in each band and return the figures together with the mean
--------------------------------------------------------------*/
WITH stats AS (
    SELECT
        AVG("loss_rate_%")  AS avg_loss_rate,
        STDDEV("loss_rate_%") AS std_loss_rate
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF
),
classified AS (
    SELECT
        CASE
            WHEN v."loss_rate_%" < s.avg_loss_rate - s.std_loss_rate THEN 'BELOW_ONE_STDDEV'
            WHEN v."loss_rate_%" > s.avg_loss_rate + s.std_loss_rate THEN 'ABOVE_ONE_STDDEV'
            ELSE 'WITHIN_ONE_STDDEV'
        END AS category
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.VEG_LOSS_RATE_DF v
    CROSS JOIN stats s
),
band_counts AS (
    SELECT category, COUNT(*) AS item_count
    FROM classified
    GROUP BY category
)
SELECT
    s.avg_loss_rate,
    COALESCE(MAX(CASE WHEN b.category = 'BELOW_ONE_STDDEV'  THEN b.item_count END), 0) AS below_one_stddev_count,
    COALESCE(MAX(CASE WHEN b.category = 'WITHIN_ONE_STDDEV' THEN b.item_count END), 0) AS within_one_stddev_count,
    COALESCE(MAX(CASE WHEN b.category = 'ABOVE_ONE_STDDEV'  THEN b.item_count END), 0) AS above_one_stddev_count
FROM stats s
LEFT JOIN band_counts b ON 1=1
GROUP BY s.avg_loss_rate;