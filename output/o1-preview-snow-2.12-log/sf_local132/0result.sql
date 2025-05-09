WITH EntertainersUpToThreeStyles AS (
    SELECT "EntertainerID"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES
    GROUP BY "EntertainerID"
    HAVING COUNT(*) <= 3
),
CustomersUpToThreePrefs AS (
    SELECT "CustomerID"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3
),
EntertainerTopStyles AS (
    SELECT es."EntertainerID", es."StyleID", es."StyleStrength"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES es
    WHERE es."EntertainerID" IN (SELECT "EntertainerID" FROM EntertainersUpToThreeStyles)
      AND es."StyleStrength" <= 2
),
CustomerTopPreferences AS (
    SELECT mp."CustomerID", mp."StyleID", mp."PreferenceSeq"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES mp
    WHERE mp."CustomerID" IN (SELECT "CustomerID" FROM CustomersUpToThreePrefs)
      AND mp."PreferenceSeq" <= 2
),
EntertainersStyles AS (
    SELECT e."EntStageName",
           MAX(CASE WHEN ets."StyleStrength" = 1 THEN ets."StyleID" END) AS "FirstStyleID",
           MAX(CASE WHEN ets."StyleStrength" = 2 THEN ets."StyleID" END) AS "SecondStyleID"
    FROM EntertainerTopStyles ets
    JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINERS e
      ON ets."EntertainerID" = e."EntertainerID"
    GROUP BY e."EntStageName"
),
CustomersPrefs AS (
    SELECT c."CustLastName",
           MAX(CASE WHEN ctp."PreferenceSeq" = 1 THEN ctp."StyleID" END) AS "FirstPrefStyleID",
           MAX(CASE WHEN ctp."PreferenceSeq" = 2 THEN ctp."StyleID" END) AS "SecondPrefStyleID"
    FROM CustomerTopPreferences ctp
    JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.CUSTOMERS c
      ON ctp."CustomerID" = c."CustomerID"
    GROUP BY c."CustLastName"
)
SELECT DISTINCT es."EntStageName", cp."CustLastName"
FROM EntertainersStyles es
JOIN CustomersPrefs cp
  ON (
       (es."FirstStyleID" = cp."FirstPrefStyleID" AND es."SecondStyleID" = cp."SecondPrefStyleID") OR
       (es."FirstStyleID" = cp."SecondPrefStyleID" AND es."SecondStyleID" = cp."FirstPrefStyleID")
     )