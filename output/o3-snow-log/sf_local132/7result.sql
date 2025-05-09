WITH
/* Customers that have 1st and 2nd musical preferences and no more than three preferences */
"CUST_PREFS" AS (
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS "Pref1",
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS "Pref2"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES"
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3                       -- up-to-three preferences
       AND COUNT(CASE WHEN "PreferenceSeq" IN (1,2) THEN 1 END) = 2  -- has both 1 & 2
),
/* Entertainers that have ranked style strengths (highest strength = 1st, next = 2nd) 
   and no more than three style rows                                            */
"ENT_STYLES" AS (
    SELECT
        "EntertainerID",
        MAX(CASE WHEN "RN" = 1 THEN "StyleID" END) AS "Style1",
        MAX(CASE WHEN "RN" = 2 THEN "StyleID" END) AS "Style2"
    FROM (
        SELECT
            "EntertainerID",
            "StyleID",
            ROW_NUMBER() OVER (PARTITION BY "EntertainerID"
                               ORDER BY "StyleStrength" DESC, "StyleID") AS "RN",
            COUNT(*)  OVER (PARTITION BY "EntertainerID")                 AS "TotalStyles"
        FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."ENTERTAINER_STYLES"
    ) AS S
    WHERE "TotalStyles" <= 3                 -- up-to-three strengths
    GROUP BY "EntertainerID"
    HAVING COUNT(CASE WHEN "RN" IN (1,2) THEN 1 END) = 2   -- has both 1st & 2nd style
)
/* Match customers to entertainers on first/second (or reversed) styles */
SELECT
    E."EntStageName"      AS "StageName",
    C."CustLastName"      AS "CustomerLastName"
FROM "ENT_STYLES"          ES
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."ENTERTAINERS" E
     ON E."EntertainerID" = ES."EntertainerID"
JOIN "CUST_PREFS"          CP
     ON  (CP."Pref1" = ES."Style1" AND CP."Pref2" = ES."Style2")
      OR (CP."Pref1" = ES."Style2" AND CP."Pref2" = ES."Style1")
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."CUSTOMERS"    C
     ON C."CustomerID"   = CP."CustomerID"
ORDER BY E."EntStageName", C."CustLastName";