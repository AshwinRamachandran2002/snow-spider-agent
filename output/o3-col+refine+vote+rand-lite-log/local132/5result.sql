SELECT DISTINCT
       en."EntStageName" AS "Entertainer",
       cu."CustLastName" AS "Customer"
FROM (
        /* customers with ≤ 3 musical‐style preferences
           + their 1st and 2nd preferences                         */
        SELECT mp."CustomerID",
               MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS pref1,
               MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS pref2
        FROM   "Musical_Preferences" AS mp
        GROUP  BY mp."CustomerID"
        HAVING COUNT(*) <= 3
     ) AS c
JOIN (
        /* entertainers with ≤ 3 style strengths
           + their 1st and 2nd strengths                              */
        SELECT es."EntertainerID",
               MAX(CASE WHEN es."StyleStrength" = 1 THEN es."StyleID" END) AS style1,
               MAX(CASE WHEN es."StyleStrength" = 2 THEN es."StyleID" END) AS style2
        FROM   "Entertainer_Styles" AS es
        GROUP  BY es."EntertainerID"
        HAVING COUNT(*) <= 3
     ) AS e
     /* match 1st & 2nd preferences to 1st & 2nd strengths
        (in the same or the reverse order)                           */
     ON  (c.pref1 = e.style1 AND c.pref2 = e.style2)
      OR (c.pref1 = e.style2 AND c.pref2 = e.style1)
JOIN "Entertainers" en ON en."EntertainerID" = e."EntertainerID"
JOIN "Customers"   cu ON cu."CustomerID"    = c."CustomerID"
ORDER BY en."EntStageName", cu."CustLastName";