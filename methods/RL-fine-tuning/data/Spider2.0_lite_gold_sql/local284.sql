WITH
  avg_loss AS (
    SELECT AVG("loss_rate_%") AS avg_loss_rate
    FROM "veg_loss_rate_df"
    WHERE "loss_rate_%" IS NOT NULL
  ),
  variance_calc AS (
    SELECT
      SUM( ( "loss_rate_%" - avg_loss.avg_loss_rate ) * ( "loss_rate_%" - avg_loss.avg_loss_rate ) ) / (COUNT(*) - 1) AS variance
    FROM
      "veg_loss_rate_df", avg_loss
    WHERE "loss_rate_%" IS NOT NULL
  ),
  sqrt_iter (iteration, x, prev_guess, guess) AS (
    SELECT
      1,
      variance_calc.variance,
      variance_calc.variance / 2.0,
      ( variance_calc.variance / 2.0 + variance_calc.variance / ( variance_calc.variance / 2.0 ) ) / 2.0
    FROM variance_calc
    UNION ALL
    SELECT
      iteration + 1,
      x,
      guess,
      ( guess + x / guess ) / 2.0
    FROM sqrt_iter
    WHERE ABS(guess - prev_guess) > 0.000001 AND iteration < 100
  ),
  std_dev_calc AS (
    SELECT guess AS std_dev
    FROM sqrt_iter
    ORDER BY iteration DESC
    LIMIT 1
  )
SELECT
  ROUND(avg_loss.avg_loss_rate, 4) AS "Average_Loss_Rate",
  SUM( CASE WHEN "loss_rate_%" < ( avg_loss.avg_loss_rate - std_dev_calc.std_dev ) THEN 1 ELSE 0 END ) AS "Num_Items_Below_One_Std_Dev",
  SUM( CASE WHEN "loss_rate_%" >= ( avg_loss.avg_loss_rate - std_dev_calc.std_dev ) AND "loss_rate_%" <= ( avg_loss.avg_loss_rate + std_dev_calc.std_dev ) THEN 1 ELSE 0 END ) AS "Num_Items_Within_One_Std_Dev",
  SUM( CASE WHEN "loss_rate_%" > ( avg_loss.avg_loss_rate + std_dev_calc.std_dev ) THEN 1 ELSE 0 END ) AS "Num_Items_Above_One_Std_Dev"
FROM
  "veg_loss_rate_df", avg_loss, std_dev_calc
WHERE
  "loss_rate_%" IS NOT NULL;