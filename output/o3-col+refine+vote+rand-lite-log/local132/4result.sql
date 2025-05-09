WITH ent AS (
    SELECT 
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS s1,
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS s2,
        COUNT(*) AS style_cnt
    FROM "Entertainer_Styles"
    GROUP BY "EntertainerID"
    HAVING style_cnt <= 3
),
cust AS (
    SELECT 
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS p1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS p2,
        COUNT(*) AS pref_cnt
    FROM "Musical_Preferences"
    GROUP BY "CustomerID"
    HAVING pref_cnt <= 3
)
SELECT DISTINCT
    en."EntStageName",
    cu."CustLastName"
FROM ent AS e
JOIN cust AS c
      ON (e.s1 = c.p1 AND e.s2 = c.p2)
      OR (e.s1 = c.p2 AND e.s2 = c.p1)
JOIN "Entertainers" AS en ON en."EntertainerID" = e."EntertainerID"
JOIN "Customers"   AS cu ON cu."CustomerID"   = c."CustomerID";