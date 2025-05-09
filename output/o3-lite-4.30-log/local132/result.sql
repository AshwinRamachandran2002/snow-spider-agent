WITH ent_two AS (                 -- entertainers with ≤3 styles
    SELECT EntertainerID,
           MAX(CASE WHEN StyleStrength = 1 THEN StyleID END) AS style1,
           MAX(CASE WHEN StyleStrength = 2 THEN StyleID END) AS style2
    FROM   Entertainer_Styles
    GROUP  BY EntertainerID
    HAVING COUNT(*) <= 3
),
cust_two AS (                     -- customers with ≤3 preferences
    SELECT CustomerID,
           MAX(CASE WHEN PreferenceSeq = 1 THEN StyleID END) AS pref1,
           MAX(CASE WHEN PreferenceSeq = 2 THEN StyleID END) AS pref2
    FROM   Musical_Preferences
    GROUP  BY CustomerID
    HAVING COUNT(*) <= 3
)
SELECT DISTINCT
       e.EntStageName AS stage_name,
       c.CustLastName AS last_name
FROM   ent_two  et
JOIN   Entertainers e ON e.EntertainerID = et.EntertainerID
CROSS  JOIN cust_two ct
JOIN   Customers  c ON c.CustomerID = ct.CustomerID
WHERE  (et.style1 = ct.pref1 AND et.style2 = ct.pref2)   -- same order
    OR (et.style1 = ct.pref2 AND et.style2 = ct.pref1)   -- reversed order
ORDER BY stage_name, last_name;