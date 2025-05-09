SELECT 
       ROUND(MAX("AvgInvoiceValue") - MIN("AvgInvoiceValue"), 4) AS "Difference_Max_Min_Avg"
FROM   (
          /* 2) average invoice value for each quarter in 2013 */
          SELECT  "Quarter",
                  AVG("InvoiceTotal") AS "AvgInvoiceValue"
          FROM   (
                     /* 1) total value of each 2013 invoice */
                     SELECT  il."InvoiceID",
                             SUM(il."Quantity" * il."UnitPrice") AS "InvoiceTotal",
                             CASE
                                  WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 1 AND 3 THEN 'Q1'
                                  WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 4 AND 6 THEN 'Q2'
                                  WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 7 AND 9 THEN 'Q3'
                                  ELSE 'Q4'
                             END AS "Quarter"
                     FROM    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICELINES" il
                     JOIN    "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES"     i
                           ON i."InvoiceID" = il."InvoiceID"
                     WHERE   SUBSTR(i."InvoiceDate", 1, 4) = '2013'
                     GROUP BY il."InvoiceID",
                              CASE
                                  WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 1 AND 3 THEN 'Q1'
                                  WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 4 AND 6 THEN 'Q2'
                                  WHEN TO_NUMBER(SUBSTR(i."InvoiceDate", 6, 2)) BETWEEN 7 AND 9 THEN 'Q3'
                                  ELSE 'Q4'
                              END
                 ) invoice_totals
          GROUP BY "Quarter"
      ) quarterly_avgs;