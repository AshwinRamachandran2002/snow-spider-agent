WITH cp AS (   -- customers with ≤ 3 preferences and their first two preferences
    SELECT  "CustomerID",
            MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS "Pref1",
            MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS "Pref2"
    FROM    "Musical_Preferences"
    GROUP BY "CustomerID"
    HAVING  COUNT(*) <= 3
),
st AS (   -- entertainers with ≤ 3 strengths and their strongest two styles
    SELECT  "EntertainerID",
            MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS "Style1",
            MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS "Style2"
    FROM    "Entertainer_Styles"
    GROUP BY "EntertainerID"
    HAVING  COUNT(*) <= 3
)
SELECT DISTINCT
       e."EntStageName",
       c."CustLastName"
FROM       cp
JOIN       st
       ON  cp."Pref1" IN (st."Style1", st."Style2")
       AND cp."Pref2" IN (st."Style1", st."Style2")
JOIN       "Customers"    c ON c."CustomerID"     = cp."CustomerID"
JOIN       "Entertainers" e ON e."EntertainerID"  = st."EntertainerID"
WHERE      cp."Pref1" IS NOT NULL
  AND      cp."Pref2" IS NOT NULL
  AND      st."Style1" IS NOT NULL
  AND      st."Style2" IS NOT NULL;