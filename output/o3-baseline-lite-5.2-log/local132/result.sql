WITH
e_styles AS (                    -- entertainers with at most 3 style strengths
    SELECT
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS style1,
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS style2
    FROM "Entertainer_Styles"
    GROUP BY "EntertainerID"
    HAVING COUNT(*) <= 3
       AND MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) IS NOT NULL
       AND MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) IS NOT NULL
),
c_prefs AS (                     -- customers with at most 3 musical preferences
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS pref1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS pref2
    FROM "Musical_Preferences"
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3
       AND MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) IS NOT NULL
       AND MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) IS NOT NULL
)
SELECT DISTINCT
       e."EntStageName",         -- entertainer’s stage name
       c."CustLastName"          -- customer’s last name
FROM e_styles es
JOIN "Entertainers" e ON e."EntertainerID" = es."EntertainerID"
JOIN c_prefs cp
     ON (es.style1 = cp.pref1 AND es.style2 = cp.pref2)     -- same order
     OR (es.style1 = cp.pref2 AND es.style2 = cp.pref1)     -- reverse order
JOIN "Customers" c ON c."CustomerID" = cp."CustomerID"
ORDER BY e."EntStageName", c."CustLastName";