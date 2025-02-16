-- Task: For each customer, display their full name, the month, and the total payment amount they made in that month.
SELECT 
    TO_CHAR(TO_TIMESTAMP(pm."payment_date"), 'MM') AS pay_mon,
    cust."first_name" || ' ' || cust."last_name" AS fullname, 
    SUM(pm."amount") AS pay_amount 
FROM 
    SQLITE_SAKILA.SQLITE_SAKILA.PAYMENT AS pm 
JOIN 
    SQLITE_SAKILA.SQLITE_SAKILA.CUSTOMER AS cust 
ON 
    pm."customer_id" = cust."customer_id" 
GROUP BY 
    1, 
    2;