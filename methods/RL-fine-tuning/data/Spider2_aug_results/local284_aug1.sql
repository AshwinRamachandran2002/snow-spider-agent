-- Task: For veg whsle data, can you generate a summary of our items' loss rates? Include the average loss rate, and also the counts of items that are above and below this average.
WITH
  avg_loss AS (
    SELECT AVG("loss_rate_%") AS avg_loss_rate
    FROM "veg_loss_rate_df"
    WHERE "loss_rate_%" IS NOT NULL
  )
SELECT
  ROUND(avg_loss.avg_loss_rate, 4) AS "Average_Loss_Rate",
  SUM( CASE WHEN "loss_rate_%" < avg_loss.avg_loss_rate THEN 1 ELSE 0 END ) AS "Num_Items_Below_Average",
  SUM( CASE WHEN "loss_rate_%" > avg_loss.avg_loss_rate THEN 1 ELSE 0 END ) AS "Num_Items_Above_Average"
FROM
  "veg_loss_rate_df", avg_loss
WHERE
  "loss_rate_%" IS NOT NULL;