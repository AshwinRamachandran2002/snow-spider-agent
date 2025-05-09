-- Description: Summary of loss-rate statistics with counts by standard-deviation bands
SELECT
       ROUND(stats.avg_loss_rate, 4)     AS avg_loss_rate,
       ROUND(stats.stddev_loss_rate, 4)  AS stddev_loss_rate,
       SUM(CASE
               WHEN v."loss_rate_%" <  stats.avg_loss_rate - stats.stddev_loss_rate THEN 1
           END)                          AS below_one_std,
       SUM(CASE
               WHEN v."loss_rate_%" BETWEEN stats.avg_loss_rate - stats.stddev_loss_rate
                                        AND     stats.avg_loss_rate + stats.stddev_loss_rate THEN 1
           END)                          AS within_one_std,
       SUM(CASE
               WHEN v."loss_rate_%" >  stats.avg_loss_rate + stats.stddev_loss_rate THEN 1
           END)                          AS above_one_std
FROM   veg_loss_rate_df AS v
CROSS JOIN (
        SELECT
               AVG("loss_rate_%")                                                         AS avg_loss_rate,
               SQRT(AVG(("loss_rate_%") * ("loss_rate_%")) -
                    AVG("loss_rate_%") * AVG("loss_rate_%"))                              AS stddev_loss_rate
        FROM   veg_loss_rate_df
) AS stats;