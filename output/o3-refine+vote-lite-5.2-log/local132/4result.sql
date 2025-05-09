WITH
-- entertainers that have no more than three documented style strengths
ent_styles AS (
    SELECT
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS Style1,
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS Style2,
        COUNT(*) AS style_cnt
    FROM "Entertainer_Styles"
    GROUP BY "EntertainerID"
    HAVING style_cnt <= 3
       AND Style1 IS NOT NULL
       AND Style2 IS NOT NULL
),
-- customers that have no more than three musical‑style preferences
cust_prefs AS (
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS Pref1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS Pref2,
        COUNT(*) AS pref_cnt
    FROM "Musical_Preferences"
    GROUP BY "CustomerID"
    HAVING pref_cnt <= 3
       AND Pref1 IS NOT NULL
       AND Pref2 IS NOT NULL
)
SELECT DISTINCT
    e."EntStageName",
    c."CustLastName"
FROM ent_styles  es
JOIN cust_prefs  cp
     ON (cp.Pref1 = es.Style1 AND cp.Pref2 = es.Style2)
     OR (cp.Pref1 = es.Style2 AND cp.Pref2 = es.Style1)
JOIN "Entertainers" e ON e."EntertainerID" = es."EntertainerID"
JOIN "Customers"   c ON c."CustomerID"   = cp."CustomerID";