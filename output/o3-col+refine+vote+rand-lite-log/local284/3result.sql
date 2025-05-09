-- Description: Summary of loss-rate statistics for items that also appear in the
--              wholesale (“veg_whsle_df”) table.
WITH whsle_items AS (                         -- items we have wholesale data for
    SELECT DISTINCT "item_code"
    FROM   "veg_whsle_df"
),
stats AS (                                    -- average loss rate for those items
    SELECT AVG(vlr."loss_rate_%") AS avg_loss
    FROM   "veg_loss_rate_df" vlr
           JOIN whsle_items wi
             ON vlr."item_code" = wi."item_code"
),
dev AS (                                      -- 1-σ standard deviation
    SELECT s.avg_loss,
           SQRT(AVG( (vlr."loss_rate_%" - s.avg_loss) *
                     (vlr."loss_rate_%" - s.avg_loss) )) AS std_dev
    FROM   "veg_loss_rate_df" vlr
           JOIN whsle_items wi
             ON vlr."item_code" = wi."item_code",
           stats s
)
SELECT d.avg_loss,
       d.std_dev,
       SUM(CASE WHEN vlr."loss_rate_%" <  d.avg_loss THEN 1 ELSE 0 END) AS count_below_avg,
       SUM(CASE WHEN vlr."loss_rate_%" >  d.avg_loss THEN 1 ELSE 0 END) AS count_above_avg,
       SUM(CASE WHEN ABS(vlr."loss_rate_%" - d.avg_loss) <= d.std_dev
                THEN 1 ELSE 0 END)                                      AS count_within_one_std
FROM   "veg_loss_rate_df" vlr
       JOIN whsle_items wi
         ON vlr."item_code" = wi."item_code",
       dev d;