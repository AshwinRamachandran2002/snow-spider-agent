WITH stats AS (
    /* average and population standard deviation of loss rates */
    SELECT
        AVG("loss_rate_%") AS avg_loss_rate,
        SQRT(AVG("loss_rate_%" * "loss_rate_%") -
             AVG("loss_rate_%") * AVG("loss_rate_%")) AS sd_loss_rate
    FROM "veg_loss_rate_df"
),
counts AS (
    /* classify each item relative to ±1 SD and count them */
    SELECT
        SUM(CASE WHEN "loss_rate_%" <  (s.avg_loss_rate - s.sd_loss_rate) THEN 1 END) AS below_1sd,
        SUM(CASE WHEN ABS("loss_rate_%" - s.avg_loss_rate) <= s.sd_loss_rate THEN 1 END) AS within_1sd,
        SUM(CASE WHEN "loss_rate_%" >  (s.avg_loss_rate + s.sd_loss_rate) THEN 1 END) AS above_1sd
    FROM "veg_loss_rate_df" v
    CROSS JOIN stats s
)
SELECT 
    ROUND(s.avg_loss_rate, 4) AS avg_loss_rate,
    c.below_1sd,
    c.within_1sd,
    c.above_1sd
FROM stats s
CROSS JOIN counts c;