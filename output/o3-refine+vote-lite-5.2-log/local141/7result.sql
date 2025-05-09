WITH yearly_sales AS (
    /* yearly total sales taken from SalesOrderHeader (before tax & freight) */
    SELECT
        salespersonid                AS businessentityid,
        strftime('%Y', orderdate)    AS year,
        SUM(subtotal)                AS total_sales
    FROM salesorderheader
    WHERE salespersonid IS NOT NULL
    GROUP BY salespersonid, year
),
yearly_quota AS (
    /* yearly sales‑quota summed from the quota history table */
    SELECT
        BusinessEntityID             AS businessentityid,
        strftime('%Y', QuotaDate)    AS year,
        SUM(SalesQuota)              AS annual_quota
    FROM SalesPersonQuotaHistory
    GROUP BY BusinessEntityID, year
),
all_years AS (
    /* build the union of every (salesperson , year) appearing in either set */
    SELECT businessentityid, year FROM yearly_sales
    UNION
    SELECT businessentityid, year FROM yearly_quota
)
SELECT
    ay.businessentityid                     AS salespersonid,
    ay.year,
    IFNULL(ys.total_sales , 0)              AS total_sales,
    IFNULL(yq.annual_quota, 0)              AS annual_quota,
    IFNULL(ys.total_sales , 0) 
      - IFNULL(yq.annual_quota, 0)          AS difference
FROM all_years ay
LEFT JOIN yearly_sales ys
       ON ay.businessentityid = ys.businessentityid
      AND ay.year            = ys.year
LEFT JOIN yearly_quota yq
       ON ay.businessentityid = yq.businessentityid
      AND ay.year            = yq.year
ORDER BY ay.businessentityid,
         ay.year;