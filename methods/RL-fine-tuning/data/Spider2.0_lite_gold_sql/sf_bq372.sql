WITH
SALES_ORDERLINES AS (
    SELECT * FROM VALUES
        (1, 10, 8, 20.0),  -- ("OrderID", "Quantity", "PickedQuantity", "UnitPrice")
        (2, 7, 7, 15.0),
        (3, 5, 3, 25.0),
        (4, 9, 6, 30.0)
    AS t("OrderID", "Quantity", "PickedQuantity", "UnitPrice")
),
SALES_ORDERS AS (
    SELECT * FROM VALUES
        (1, 101),
        (2, 102),
        (3, 103),
        (4, 104)
    AS t("OrderID", "CustomerID")
),
SALES_CUSTOMERS AS (
    SELECT * FROM VALUES
        (101, 1),
        (102, 2),
        (103, 1),
        (104, 2)
    AS t("CustomerID", "CustomerCategoryID")
),
SALES_CUSTOMERCATEGORIES AS (
    SELECT * FROM VALUES
        (1, 'Retail'),
        (2, 'Wholesale')
    AS t("CustomerCategoryID", "CustomerCategoryName")
),
LostOrderValues AS (
    SELECT
        o."CustomerID",
        SUM( ("Quantity" - "PickedQuantity") * "UnitPrice" ) AS "TotalLostValue"
    FROM SALES_ORDERLINES ol
    JOIN SALES_ORDERS o ON ol."OrderID" = o."OrderID"
    WHERE "Quantity" > "PickedQuantity"
    GROUP BY o."CustomerID"
),
MaxLostValues AS (
    SELECT
        c."CustomerCategoryID",
        MAX(lov."TotalLostValue") AS "MaxLostValue"
    FROM SALES_CUSTOMERS c
    JOIN LostOrderValues lov ON c."CustomerID" = lov."CustomerID"
    GROUP BY c."CustomerCategoryID"
),
AverageMaxLost AS (
    SELECT AVG("MaxLostValue") AS "AverageMaxLostValue" FROM MaxLostValues
),
ClosestCategory AS (
    SELECT
        m."CustomerCategoryID",
        m."MaxLostValue",
        ABS(m."MaxLostValue" - (SELECT "AverageMaxLostValue" FROM AverageMaxLost)) AS "Difference"
    FROM MaxLostValues m
    ORDER BY "Difference" ASC NULLS LAST
    LIMIT 1
)
SELECT
    cc."CustomerCategoryName",
    ROUND(c."MaxLostValue", 4) AS "MaximumLostOrderValue"
FROM ClosestCategory c
JOIN SALES_CUSTOMERCATEGORIES cc
    ON c."CustomerCategoryID" = cc."CustomerCategoryID";