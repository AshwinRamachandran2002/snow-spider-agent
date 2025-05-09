-- Description: Average loss-rate plus counts of items
--              that fall below, within and above ±1 SD
WITH stats AS (
    SELECT
        AVG("loss_rate_%")                                                                 AS avg_loss,
        SQRT(
            AVG(
                ("loss_rate_%" - (SELECT AVG("loss_rate_%") FROM "veg_loss_rate_df")) *
                ("loss_rate_%" - (SELECT AVG("loss_rate_%") FROM "veg_loss_rate_df"))
            )
        )                                                                                 AS std_dev
    FROM "veg_loss_rate_df"
)
SELECT
    ROUND((SELECT avg_loss FROM stats), 4)                           AS avg_loss_rate,
    SUM(
        CASE
            WHEN "loss_rate_%" < (SELECT avg_loss - std_dev FROM stats) THEN 1
            ELSE 0
        END
    )                                                               AS cnt_below_1SD,
    SUM(
        CASE
            WHEN "loss_rate_%" BETWEEN
                 (SELECT avg_loss - std_dev FROM stats) AND
                 (SELECT avg_loss + std_dev FROM stats) THEN 1
            ELSE 0
        END
    )                                                               AS cnt_within_1SD,
    SUM(
        CASE
            WHEN "loss_rate_%" > (SELECT avg_loss + std_dev FROM stats) THEN 1
            ELSE 0
        END
    )                                                               AS cnt_above_1SD
FROM "veg_loss_rate_df";