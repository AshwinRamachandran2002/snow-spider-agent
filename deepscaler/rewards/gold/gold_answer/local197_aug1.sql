-- Task: Compute the total number of payments and total amount paid per customer per month.

SELECT 
  strftime('%m', pm.payment_date) AS pay_mon, 
  pm.customer_id,
  COUNT(pm.amount) AS pay_countpermon, 
  SUM(pm.amount) AS pay_amount
FROM 
  payment AS pm 
GROUP BY 
  pay_mon, 
  pm.customer_id;