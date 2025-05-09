WITH ENT_STYLES AS (
    /* entertainers that have 1st and 2nd strengths and no more than 3 strengths in total */
    SELECT 
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS STYLE1,
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS STYLE2
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES
    GROUP BY "EntertainerID"
    HAVING COUNT(*) <= 3                                 -- up-to-three strengths
           AND MAX(CASE WHEN "StyleStrength" = 1 THEN 1 END) IS NOT NULL   -- has 1st strength
           AND MAX(CASE WHEN "StyleStrength" = 2 THEN 1 END) IS NOT NULL   -- has 2nd strength
), CUST_PREFS AS (
    /* customers that have 1st and 2nd preferences and no more than 3 preferences in total */
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS PREF1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS PREF2
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3                                  -- up-to-three preferences
           AND MAX(CASE WHEN "PreferenceSeq" = 1 THEN 1 END) IS NOT NULL   -- has 1st pref
           AND MAX(CASE WHEN "PreferenceSeq" = 2 THEN 1 END) IS NOT NULL   -- has 2nd pref
)
SELECT DISTINCT
       E."EntStageName"  AS "EntStageName",
       C."CustLastName"  AS "CustLastName"
FROM ENT_STYLES ES
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINERS  E
     ON E."EntertainerID" = ES."EntertainerID"
JOIN CUST_PREFS CP
     /* match (1,2) with (1,2) or (1,2) with (2,1) */
     ON (ES.STYLE1 = CP.PREF1 AND ES.STYLE2 = CP.PREF2)
        OR (ES.STYLE1 = CP.PREF2 AND ES.STYLE2 = CP.PREF1)
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.CUSTOMERS     C
     ON C."CustomerID" = CP."CustomerID";