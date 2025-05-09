WITH "ENT_STYLES" AS (            -- entertainers having no more than 3 styles
    SELECT
        es."EntertainerID",
        MAX(CASE WHEN es."StyleStrength" = 1 THEN es."StyleID" END) AS "Style1",
        MAX(CASE WHEN es."StyleStrength" = 2 THEN es."StyleID" END) AS "Style2"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."ENTERTAINER_STYLES" es
    GROUP BY es."EntertainerID"
    HAVING COUNT(es."StyleID") <= 3
       AND COUNT(CASE WHEN es."StyleStrength" IN (1,2) THEN 1 END) = 2   -- must have both 1st & 2nd strengths
), 
"CUST_PREFS" AS (                -- customers having no more than 3 preferences
    SELECT
        mp."CustomerID",
        MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS "Pref1",
        MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS "Pref2"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES" mp
    GROUP BY mp."CustomerID"
    HAVING COUNT(mp."StyleID") <= 3
       AND COUNT(CASE WHEN mp."PreferenceSeq" IN (1,2) THEN 1 END) = 2   -- must have both 1st & 2nd prefs
)

SELECT DISTINCT
       et."EntStageName",
       cu."CustLastName"
FROM "ENT_STYLES"  es
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."ENTERTAINERS" et
     ON es."EntertainerID" = et."EntertainerID"
JOIN "CUST_PREFS"   cp
     ON (es."Style1" = cp."Pref1" AND es."Style2" = cp."Pref2")
      OR (es."Style1" = cp."Pref2" AND es."Style2" = cp."Pref1")
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."CUSTOMERS" cu
     ON cp."CustomerID" = cu."CustomerID";