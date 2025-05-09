/*  Average loss-rate and item counts relative to one standard deviation */
WITH stats AS (
    SELECT
        AVG("loss_rate_%")                                             AS avg_loss,
        SQRT( AVG("loss_rate_%" * "loss_rate_%") -
              AVG("loss_rate_%") * AVG("loss_rate_%") )               AS std_loss
    FROM "veg_loss_rate_df"
),
summary AS (
    SELECT
        SUM(CASE WHEN v."loss_rate_%" <  s.avg_loss                     THEN 1 ELSE 0 END) AS below_avg,
        SUM(CASE WHEN v."loss_rate_%" BETWEEN s.avg_loss - s.std_loss
                                       AND     s.avg_loss + s.std_loss THEN 1 ELSE 0 END) AS within_one_std,
        SUM(CASE WHEN v."loss_rate_%" >  s.avg_loss                     THEN 1 ELSE 0 END) AS above_avg
    FROM "veg_loss_rate_df" AS v
    CROSS JOIN stats AS s
)
SELECT
    ROUND(s.avg_loss, 4)  AS avg_loss_rate,
    summary.below_avg,
    summary.within_one_std,
    summary.above_avg
FROM stats   AS s
CROSS JOIN summary;