WITH EntertainerStyles AS (
    SELECT e."EntertainerID", e."EntStageName", 
        MAX(CASE WHEN es."StyleStrength" = 1 THEN es."StyleID" END) AS "FirstStyleID",
        MAX(CASE WHEN es."StyleStrength" = 2 THEN es."StyleID" END) AS "SecondStyleID",
        COUNT(*) AS "StyleCount"
    FROM "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINERS" e
    JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINER_STYLES" es
        ON e."EntertainerID" = es."EntertainerID"
    GROUP BY e."EntertainerID", e."EntStageName"
    HAVING COUNT(*) <= 3
),
CustomerPrefs AS (
    SELECT c."CustomerID", c."CustLastName",
        MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS "FirstPrefStyleID",
        MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS "SecondPrefStyleID",
        COUNT(*) AS "PrefCount"
    FROM "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."CUSTOMERS" c
    JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_PREFERENCES" mp
        ON c."CustomerID" = mp."CustomerID"
    GROUP BY c."CustomerID", c."CustLastName"
    HAVING COUNT(*) <= 3
)
SELECT es."EntStageName", cp."CustLastName"
FROM EntertainerStyles es
JOIN CustomerPrefs cp
    ON (es."FirstStyleID" = cp."FirstPrefStyleID" AND es."SecondStyleID" = cp."SecondPrefStyleID")
       OR
       (es."FirstStyleID" = cp."SecondPrefStyleID" AND es."SecondStyleID" = cp."FirstPrefStyleID");