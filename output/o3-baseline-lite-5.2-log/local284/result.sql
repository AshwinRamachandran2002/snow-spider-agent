WITH stats AS (
    SELECT
        AVG("loss_rate_%") AS avg_rate,
        AVG("loss_rate_%" * "loss_rate_%") - AVG("loss_rate_%") * AVG("loss_rate_%") AS variance
    FROM veg_loss_rate_df
),
categorized AS (
    SELECT
        CASE
            WHEN (v."loss_rate_%" - s.avg_rate) < 0
                 AND (v."loss_rate_%" - s.avg_rate)*(v."loss_rate_%" - s.avg_rate) > s.variance THEN 'below'
            WHEN (v."loss_rate_%" - s.avg_rate) > 0
                 AND (v."loss_rate_%" - s.avg_rate)*(v."loss_rate_%" - s.avg_rate) > s.variance THEN 'above'
            ELSE 'within'
        END AS category
    FROM veg_loss_rate_df v
    CROSS JOIN stats s
)
SELECT
    ROUND((SELECT avg_rate FROM stats), 4) AS average_loss_rate,
    SUM(CASE WHEN category = 'below'  THEN 1 ELSE 0 END) AS count_below_one_stddev,
    SUM(CASE WHEN category = 'within' THEN 1 ELSE 0 END) AS count_within_one_stddev,
    SUM(CASE WHEN category = 'above'  THEN 1 ELSE 0 END) AS count_above_one_stddev
FROM categorized;