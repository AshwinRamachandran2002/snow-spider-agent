WITH stats AS (
    SELECT
        AVG("loss_rate_%") AS avg_loss_rate,
        -- variance = E[x²] − (E[x])²
        AVG(("loss_rate_%") * ("loss_rate_%")) 
        - AVG("loss_rate_%") * AVG("loss_rate_%") AS var_loss_rate
    FROM "veg_loss_rate_df"
)
SELECT
    s.avg_loss_rate,
    SUM(
        CASE
            WHEN ((v."loss_rate_%" - s.avg_loss_rate) * (v."loss_rate_%" - s.avg_loss_rate) > s.var_loss_rate)
                 AND v."loss_rate_%" < s.avg_loss_rate
            THEN 1 ELSE 0
        END
    ) AS count_below_one_std,
    SUM(
        CASE
            WHEN ((v."loss_rate_%" - s.avg_loss_rate) * (v."loss_rate_%" - s.avg_loss_rate) <= s.var_loss_rate)
            THEN 1 ELSE 0
        END
    ) AS count_within_one_std,
    SUM(
        CASE
            WHEN ((v."loss_rate_%" - s.avg_loss_rate) * (v."loss_rate_%" - s.avg_loss_rate) > s.var_loss_rate)
                 AND v."loss_rate_%" > s.avg_loss_rate
            THEN 1 ELSE 0
        END
    ) AS count_above_one_std
FROM "veg_loss_rate_df" v
CROSS JOIN stats s;