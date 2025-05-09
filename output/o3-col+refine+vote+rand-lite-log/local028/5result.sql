WITH months(month) AS (
  VALUES
    ('01'), ('02'), ('03'), ('04'), ('05'), ('06'),
    ('07'), ('08'), ('09'), ('10'), ('11'), ('12')
)
SELECT
    months.month,
    SUM(CASE WHEN substr(o."order_delivered_customer_date",1,4) = '2016' THEN 1 ELSE 0 END) AS "2016",
    SUM(CASE WHEN substr(o."order_delivered_customer_date",1,4) = '2017' THEN 1 ELSE 0 END) AS "2017",
    SUM(CASE WHEN substr(o."order_delivered_customer_date",1,4) = '2018' THEN 1 ELSE 0 END) AS "2018"
FROM   months
LEFT JOIN "olist_orders" o
       ON substr(o."order_delivered_customer_date",6,2) = months.month
      AND o."order_status" = 'delivered'
      AND substr(o."order_delivered_customer_date",1,4) IN ('2016','2017','2018')
GROUP  BY months.month
ORDER  BY months.month;