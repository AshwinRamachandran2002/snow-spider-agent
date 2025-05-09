WITH ent AS (
    SELECT
        es.EntertainerID,
        MAX(CASE WHEN es.StyleStrength = 1 THEN es.StyleID END) AS style1,
        MAX(CASE WHEN es.StyleStrength = 2 THEN es.StyleID END) AS style2
    FROM Entertainer_Styles AS es
    GROUP BY es.EntertainerID
    HAVING
        COUNT(*) <= 3
        AND MAX(CASE WHEN es.StyleStrength = 1 THEN es.StyleID END) IS NOT NULL
        AND MAX(CASE WHEN es.StyleStrength = 2 THEN es.StyleID END) IS NOT NULL
),
cust AS (
    SELECT
        mp.CustomerID,
        MAX(CASE WHEN mp.PreferenceSeq = 1 THEN mp.StyleID END) AS pref1,
        MAX(CASE WHEN mp.PreferenceSeq = 2 THEN mp.StyleID END) AS pref2
    FROM Musical_Preferences AS mp
    GROUP BY mp.CustomerID
    HAVING
        COUNT(*) <= 3
        AND MAX(CASE WHEN mp.PreferenceSeq = 1 THEN mp.StyleID END) IS NOT NULL
        AND MAX(CASE WHEN mp.PreferenceSeq = 2 THEN mp.StyleID END) IS NOT NULL
)
SELECT DISTINCT
    e.EntStageName AS stage_name,
    c.CustLastName AS last_name
FROM ent
JOIN Entertainers AS e ON e.EntertainerID = ent.EntertainerID
JOIN cust
JOIN Customers   AS c ON c.CustomerID     = cust.CustomerID
WHERE
      (ent.style1 = cust.pref1 AND ent.style2 = cust.pref2)
   OR (ent.style1 = cust.pref2 AND ent.style2 = cust.pref1)
ORDER BY
    stage_name,
    last_name;