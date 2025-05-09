/* 1) Pick entertainers that have no more than three style–strength rows
      and keep the StyleID for strength 1 and 2                     */
WITH Ent AS (
    SELECT
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS Style1,
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS Style2,
        COUNT(*)                                              AS CntStyles
    FROM   "Entertainer_Styles"
    GROUP  BY "EntertainerID"
    HAVING CntStyles <= 3
       AND Style1 IS NOT NULL
       AND Style2 IS NOT NULL
),

/* 2) Pick customers that have no more than three musical‑preference
      rows and keep the StyleID for preference 1 and 2              */
Cust AS (
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS Pref1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS Pref2,
        COUNT(*)                                              AS CntPref
    FROM   "Musical_Preferences"
    GROUP  BY "CustomerID"
    HAVING CntPref <= 3
       AND Pref1 IS NOT NULL
       AND Pref2 IS NOT NULL
)

/* 3) Match first‑&‑second (or second‑&‑first) styles                */
SELECT DISTINCT
       e."EntStageName",
       cu."CustLastName"
FROM   Ent  es
JOIN   "Entertainers" e  ON e."EntertainerID" = es."EntertainerID"
JOIN   Cust cs           ON  (cs.Pref1 = es.Style1 AND cs.Pref2 = es.Style2)
                         OR  (cs.Pref1 = es.Style2 AND cs.Pref2 = es.Style1)
JOIN   "Customers" cu    ON cu."CustomerID" = cs."CustomerID";