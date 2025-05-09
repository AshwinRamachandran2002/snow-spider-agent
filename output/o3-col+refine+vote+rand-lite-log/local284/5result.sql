/* Average loss-rate across all items and how many items
   fall below, within, or above one standard deviation
   from that average                                                */
WITH stats AS (
    SELECT  AVG("loss_rate_%")                                                   AS avg_loss,
            sqrt( AVG("loss_rate_%*"||"loss_rate_%") -                           -- E[X²] – (E[X])²
                  AVG("loss_rate_%")*AVG("loss_rate_%") )                        AS sd
    FROM    "veg_loss_rate_df"
    WHERE   "loss_rate_%" IS NOT NULL
),
classified AS (
    SELECT CASE
             WHEN v."loss_rate_%" < s.avg_loss - s.sd THEN 'below_1_sd'
             WHEN v."loss_rate_%" > s.avg_loss + s.sd THEN 'above_1_sd'
             ELSE                               'within_1_sd'
           END  AS band
    FROM   "veg_loss_rate_df" v
    CROSS  JOIN stats s
    WHERE  v."loss_rate_%" IS NOT NULL
)
SELECT ROUND((SELECT avg_loss FROM stats),4)                     AS average_loss_rate,
       SUM(CASE WHEN band='below_1_sd'  THEN 1 END)              AS below_1_sd_count,
       SUM(CASE WHEN band='within_1_sd' THEN 1 END)              AS within_1_sd_count,
       SUM(CASE WHEN band='above_1_sd'  THEN 1 END)              AS above_1_sd_count
FROM   classified;