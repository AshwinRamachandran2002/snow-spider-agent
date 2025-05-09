WITH Ent AS (                       -- entertainers: keep strengths #1 and #2
    SELECT
        es."EntertainerID",
        MAX(CASE WHEN es."StyleStrength" = 1 THEN es."StyleID" END) AS S1,
        MAX(CASE WHEN es."StyleStrength" = 2 THEN es."StyleID" END) AS S2
    FROM "Entertainer_Styles" AS es
    GROUP BY es."EntertainerID"
    HAVING COUNT(*) <= 3
),
Cust AS (                           -- customers: keep preferences #1 and #2
    SELECT
        mp."CustomerID",
        MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS P1,
        MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS P2
    FROM "Musical_Preferences" AS mp
    GROUP BY mp."CustomerID"
    HAVING COUNT(*) <= 3
),
Pairs AS (                          -- matching pairs (either order)
    SELECT DISTINCT
        e."EntertainerID",
        c."CustomerID"
    FROM Ent e
    JOIN Cust c
      ON (c.P1 = e.S1 AND c.P2 = e.S2)      -- same order
       OR (c.P1 = e.S2 AND c.P2 = e.S1)     -- reverse order
)
SELECT DISTINCT
       en."EntStageName",
       cu."CustLastName"
FROM   Pairs        p
JOIN   "Entertainers" en ON en."EntertainerID" = p."EntertainerID"
JOIN   "Customers"    cu ON cu."CustomerID"    = p."CustomerID";