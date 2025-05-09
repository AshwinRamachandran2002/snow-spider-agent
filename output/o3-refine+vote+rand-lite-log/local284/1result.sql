WITH stats AS (
    SELECT
        AVG("loss_rate_%")                                                       AS avg_loss_rate,
        AVG(("loss_rate_%") * ("loss_rate_%")) 
          - AVG("loss_rate_%") * AVG("loss_rate_%")                              AS variance
    FROM "veg_loss_rate_df"
),
classified AS (
    SELECT
        CASE
            WHEN ((v."loss_rate_%" - s.avg_loss_rate) * (v."loss_rate_%" - s.avg_loss_rate)) 
                 <= s.variance                                   THEN 'within'
            WHEN v."loss_rate_%" <  s.avg_loss_rate              THEN 'below'
            ELSE                                                     'above'
        END AS segment
    FROM "veg_loss_rate_df" v
    CROSS JOIN stats s
)
SELECT
    (SELECT avg_loss_rate FROM stats)                             AS avg_loss_rate,
    SUM(CASE WHEN segment = 'below'  THEN 1 ELSE 0 END)           AS count_below_one_sd,
    SUM(CASE WHEN segment = 'within' THEN 1 ELSE 0 END)           AS count_within_one_sd,
    SUM(CASE WHEN segment = 'above'  THEN 1 ELSE 0 END)           AS count_above_one_sd
FROM classified;