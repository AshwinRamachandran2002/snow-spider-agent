SELECT DISTINCT
       en."EntStageName",
       cu."CustLastName"
FROM   (
         SELECT  "EntertainerID",
                 MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS S1,
                 MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS S2
         FROM    "Entertainer_Styles"
         GROUP  BY "EntertainerID"
         HAVING  COUNT(*) <= 3
       ) AS e
JOIN   (
         SELECT  "CustomerID",
                 MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS P1,
                 MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS P2
         FROM    "Musical_Preferences"
         GROUP  BY "CustomerID"
         HAVING  COUNT(*) <= 3
       ) AS c
       ON (e.S1 = c.P1 AND e.S2 = c.P2)      -- same order
        OR (e.S1 = c.P2 AND e.S2 = c.P1)     -- reverse order
JOIN   "Entertainers" AS en ON en."EntertainerID" = e."EntertainerID"
JOIN   "Customers"    AS cu ON cu."CustomerID"    = c."CustomerID"
ORDER BY en."EntStageName", cu."CustLastName";