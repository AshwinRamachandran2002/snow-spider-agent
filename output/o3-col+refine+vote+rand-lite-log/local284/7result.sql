WITH base AS (                         -- overall mean (µ)
    SELECT AVG("loss_rate_%") AS mu
    FROM   "veg_loss_rate_df"
),
stats AS (                            -- standard deviation (σ)
    SELECT base.mu,
           SQRT(AVG(POWER(v."loss_rate_%" - base.mu, 2))) AS sd
    FROM   "veg_loss_rate_df" v
    CROSS  JOIN base
),
banded AS (                           -- classify each item relative to µ ± σ
    SELECT CASE
               WHEN v."loss_rate_%" <  s.mu - s.sd THEN 'Below 1 SD'
               WHEN v."loss_rate_%" >  s.mu + s.sd THEN 'Above 1 SD'
               ELSE                               'Within ±1 SD'
           END AS band
    FROM   "veg_loss_rate_df" v
    CROSS  JOIN stats s
)
SELECT 
    ROUND(stats.mu, 4)                     AS avg_loss_rate_pct,
    ROUND(stats.sd, 4)                     AS stdev_loss_rate_pct,
    SUM(CASE WHEN band = 'Below 1 SD'  THEN 1 ELSE 0 END) AS items_below_1_SD,
    SUM(CASE WHEN band = 'Within ±1 SD' THEN 1 ELSE 0 END) AS items_within_1_SD,
    SUM(CASE WHEN band = 'Above 1 SD'  THEN 1 ELSE 0 END) AS items_above_1_SD
FROM   stats
CROSS  JOIN banded;