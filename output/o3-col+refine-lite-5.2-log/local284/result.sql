WITH stats AS (
    SELECT
        AVG("loss_rate_%")                                                    AS avg_loss,
        AVG(("loss_rate_%") * ("loss_rate_%")) -
        AVG("loss_rate_%") * AVG("loss_rate_%")                               AS var_loss      -- variance
    FROM "veg_loss_rate_df"
),
banded AS (
    SELECT
        CASE
            WHEN ((v."loss_rate_%" - s.avg_loss) * (v."loss_rate_%" - s.avg_loss)) > s.var_loss
                 AND v."loss_rate_%" < s.avg_loss  THEN 'Below 1 SD'
            WHEN ((v."loss_rate_%" - s.avg_loss) * (v."loss_rate_%" - s.avg_loss)) > s.var_loss
                 AND v."loss_rate_%" > s.avg_loss  THEN 'Above 1 SD'
            ELSE                                       'Within 1 SD'
        END AS range_flag
    FROM "veg_loss_rate_df" AS v
    CROSS JOIN stats AS s
)
SELECT
    (SELECT avg_loss FROM stats)                                 AS average_loss_rate,
    SUM(CASE WHEN range_flag = 'Below 1 SD'  THEN 1 ELSE 0 END)  AS items_below_1sd,
    SUM(CASE WHEN range_flag = 'Within 1 SD' THEN 1 ELSE 0 END)  AS items_within_1sd,
    SUM(CASE WHEN range_flag = 'Above 1 SD'  THEN 1 ELSE 0 END)  AS items_above_1sd
FROM banded;