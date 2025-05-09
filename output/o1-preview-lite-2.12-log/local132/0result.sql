WITH
Customer_Prefs AS (
    SELECT mp."CustomerID", mp."PreferenceSeq", mp."StyleID"
    FROM "Musical_Preferences" mp
    WHERE mp."PreferenceSeq" IN (1, 2)
    AND mp."CustomerID" IN (
        SELECT "CustomerID"
        FROM "Musical_Preferences"
        GROUP BY "CustomerID"
        HAVING COUNT(*) <= 3
    )
),
Customer_Pref_Table AS (
    SELECT cp1."CustomerID",
           cp1."StyleID" AS "FirstPreferenceStyleID",
           cp2."StyleID" AS "SecondPreferenceStyleID"
    FROM Customer_Prefs cp1
    LEFT JOIN Customer_Prefs cp2
    ON cp1."CustomerID" = cp2."CustomerID" AND cp2."PreferenceSeq" = 2
    WHERE cp1."PreferenceSeq" = 1
),
Customer_Info AS (
    SELECT cpt."CustomerID", c."CustLastName", cpt."FirstPreferenceStyleID", cpt."SecondPreferenceStyleID"
    FROM Customer_Pref_Table cpt
    JOIN "Customers" c ON cpt."CustomerID" = c."CustomerID"
),
Entertainer_Styles_Ranked AS (
    SELECT es."EntertainerID", es."StyleID", es."StyleStrength",
           ROW_NUMBER() OVER (PARTITION BY es."EntertainerID" ORDER BY es."StyleStrength" DESC) AS StyleRank
    FROM "Entertainer_Styles" es
    WHERE es."EntertainerID" IN (
        SELECT "EntertainerID"
        FROM "Entertainer_Styles"
        GROUP BY "EntertainerID"
        HAVING COUNT(*) <= 3
    )
),
Entertainer_Styles_Top2 AS (
    SELECT esr."EntertainerID",
           MAX(CASE WHEN esr.StyleRank = 1 THEN esr."StyleID" END) AS "FirstStyleID",
           MAX(CASE WHEN esr.StyleRank = 2 THEN esr."StyleID" END) AS "SecondStyleID"
    FROM Entertainer_Styles_Ranked esr
    WHERE esr.StyleRank <= 2
    GROUP BY esr."EntertainerID"
),
Entertainer_Info AS (
    SELECT est2."EntertainerID", e."EntStageName", est2."FirstStyleID", est2."SecondStyleID"
    FROM Entertainer_Styles_Top2 est2
    JOIN "Entertainers" e ON est2."EntertainerID" = e."EntertainerID"
)
SELECT DISTINCT ei."EntStageName", ci."CustLastName"
FROM Customer_Info ci
CROSS JOIN Entertainer_Info ei
WHERE
    (
        ci."FirstPreferenceStyleID" = ei."FirstStyleID" AND ci."SecondPreferenceStyleID" = ei."SecondStyleID"
    )
    OR
    (
        ci."FirstPreferenceStyleID" = ei."SecondStyleID" AND ci."SecondPreferenceStyleID" = ei."FirstStyleID"
    )
;