SELECT
    "employeeid" AS EmployeeID,
    SUM(
        CASE
            WHEN TO_DATE("shippeddate", 'YYYY-MM-DD') >= TO_DATE("requireddate", 'YYYY-MM-DD') THEN 1
            ELSE 0
        END
    ) AS Number_of_Late_Orders,
    ROUND(
        (SUM(
            CASE
                WHEN TO_DATE("shippeddate", 'YYYY-MM-DD') >= TO_DATE("requireddate", 'YYYY-MM-DD') THEN 1
                ELSE 0
            END
        )::FLOAT / COUNT(*)) * 100,
        4
    ) AS Late_Order_Percentage
FROM
    "NORTHWIND"."NORTHWIND"."ORDERS"
WHERE
    "employeeid" IS NOT NULL
    AND "requireddate" IS NOT NULL
    AND "requireddate" <> ''
    AND "shippeddate" IS NOT NULL
    AND "shippeddate" <> ''
GROUP BY
    "employeeid"
HAVING
    COUNT(*) > 50
ORDER BY
    Late_Order_Percentage DESC NULLS LAST,
    Number_of_Late_Orders DESC,
    EmployeeID ASC
LIMIT
    3;