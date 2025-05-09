/* -------------------------------------------
   Average loss‑rate, its standard deviation,
   and item counts below / within / above
   one standard deviation of the mean
   ------------------------------------------- */
WITH stats AS (               /* basic moments */
    SELECT
        AVG("loss_rate_%")                                       AS mean,
        AVG(("loss_rate_%") * ("loss_rate_%")) -
        AVG("loss_rate_%") * AVG("loss_rate_%")                  AS variance
    FROM "veg_loss_rate_df"
),

/* --- derive √variance (Newton’s method – 20 iterations) ------------- */
sqrt_iter(iter, est) AS (
    /* seed value */
    SELECT 0,
           CASE WHEN (SELECT variance FROM stats)=0
                THEN 0
                ELSE (SELECT variance FROM stats)/2.0 END
    UNION ALL
    SELECT iter+1,
           CASE WHEN (SELECT variance FROM stats)=0
                THEN 0
                ELSE 0.5*(est + (SELECT variance FROM stats)/est) END
    FROM sqrt_iter
    WHERE iter < 20
),

final_stats AS (              /* collect final figures */
    SELECT
        mean,
        variance,
        (SELECT est FROM sqrt_iter ORDER BY iter DESC LIMIT 1) AS stddev
    FROM stats
)

SELECT
    ROUND(fs.mean, 4) AS average_loss_rate,
    ROUND(fs.stddev, 4) AS standard_deviation,

    /* below one std‑dev (far below mean) */
    SUM(
        CASE
            WHEN v."loss_rate_%" < fs.mean
                 AND (v."loss_rate_%" - fs.mean)*(v."loss_rate_%" - fs.mean) > fs.variance
            THEN 1
        END
    ) AS count_below_one_std,

    /* within one std‑dev of the mean */
    SUM(
        CASE
            WHEN (v."loss_rate_%" - fs.mean)*(v."loss_rate_%" - fs.mean) <= fs.variance
            THEN 1
        END
    ) AS count_within_one_std,

    /* above one std‑dev (far above mean) */
    SUM(
        CASE
            WHEN v."loss_rate_%" > fs.mean
                 AND (v."loss_rate_%" - fs.mean)*(v."loss_rate_%" - fs.mean) > fs.variance
            THEN 1
        END
    ) AS count_above_one_std
FROM "veg_loss_rate_df" v
CROSS JOIN final_stats fs;