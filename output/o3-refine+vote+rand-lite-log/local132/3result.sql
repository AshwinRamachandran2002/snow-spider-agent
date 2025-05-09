WITH ent_rank AS (
    SELECT 
        "EntertainerID",
        "StyleID",
        ROW_NUMBER() OVER (PARTITION BY "EntertainerID" 
                           ORDER BY "StyleStrength")          AS rn,
        COUNT(*)    OVER (PARTITION BY "EntertainerID")        AS tot_cnt
    FROM "Entertainer_Styles"
),
ent_pivot AS (
    /* entertainers that have no more than three styles
       and at least two, captured as style1 / style2      */
    SELECT 
        "EntertainerID",
        MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS e_style1,
        MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS e_style2
    FROM ent_rank
    WHERE tot_cnt <= 3
    GROUP BY "EntertainerID"
    HAVING COUNT(CASE WHEN rn <= 2 THEN 1 END) = 2
),
cust_rank AS (
    SELECT 
        "CustomerID",
        "StyleID",
        ROW_NUMBER() OVER (PARTITION BY "CustomerID" 
                           ORDER BY "PreferenceSeq")           AS rn,
        COUNT(*)    OVER (PARTITION BY "CustomerID")           AS tot_cnt
    FROM "Musical_Preferences"
),
cust_pivot AS (
    /* customers that have no more than three preferences
       and at least two, captured as style1 / style2          */
    SELECT 
        "CustomerID",
        MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS c_style1,
        MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS c_style2
    FROM cust_rank
    WHERE tot_cnt <= 3
    GROUP BY "CustomerID"
    HAVING COUNT(CASE WHEN rn <= 2 THEN 1 END) = 2
)
SELECT DISTINCT  
       e."EntStageName", 
       c."CustLastName"
FROM   ent_pivot  ep
JOIN   "Entertainers" e 
       ON e."EntertainerID" = ep."EntertainerID"
CROSS  JOIN cust_pivot  cp
JOIN   "Customers"   c 
       ON c."CustomerID" = cp."CustomerID"
WHERE  (ep.e_style1 = cp.c_style1 AND ep.e_style2 = cp.c_style2)
    OR (ep.e_style1 = cp.c_style2 AND ep.e_style2 = cp.c_style1)
ORDER BY e."EntStageName", c."CustLastName";