/*  Pairs of customers & entertainers whose 1st‑two style
    preferences/strengths match (in the same or reverse order),
    and who have no more than three total styles each          */
SELECT DISTINCT
       e."EntStageName",
       c."CustLastName"
FROM  /* --- customers: keep only those with ≤ 3 preferences
                and both 1st & 2nd preferences present ------- */
      (SELECT  mp."CustomerID",
               MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS "Pref1",
               MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS "Pref2"
       FROM    "Musical_Preferences" AS mp
       GROUP BY mp."CustomerID"
       HAVING  COUNT(*) <= 3
           AND MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) IS NOT NULL
           AND MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) IS NOT NULL
      ) AS cu
JOIN  "Customers"         AS c  ON c."CustomerID" = cu."CustomerID"

     /* --- entertainers: keep only those with ≤ 3 strengths
                and both 1st & 2nd strengths present ---------- */
JOIN  (SELECT  es."EntertainerID",
               MAX(CASE WHEN es."StyleStrength" = 1 THEN es."StyleID" END) AS "Style1",
               MAX(CASE WHEN es."StyleStrength" = 2 THEN es."StyleID" END) AS "Style2"
        FROM   "Entertainer_Styles" AS es
        GROUP  BY es."EntertainerID"
        HAVING COUNT(*) <= 3
           AND MAX(CASE WHEN es."StyleStrength" = 1 THEN es."StyleID" END) IS NOT NULL
           AND MAX(CASE WHEN es."StyleStrength" = 2 THEN es."StyleID" END) IS NOT NULL
      ) AS en
          /* match same order OR reverse order */
      ON (en."Style1" = cu."Pref1" AND en."Style2" = cu."Pref2")
       OR (en."Style1" = cu."Pref2" AND en."Style2" = cu."Pref1")

JOIN  "Entertainers"      AS e  ON e."EntertainerID" = en."EntertainerID";