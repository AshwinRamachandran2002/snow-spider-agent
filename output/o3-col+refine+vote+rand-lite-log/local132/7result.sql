WITH e AS (   -- entertainers: keep only those with 1st and 2nd strengths recorded, no strength higher than 3
    SELECT "EntertainerID",
           MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS "Style1",
           MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS "Style2"
    FROM   "Entertainer_Styles"
    GROUP  BY "EntertainerID"
    HAVING MAX("StyleStrength") <= 3
       AND COUNT(CASE WHEN "StyleStrength" IN (1,2) THEN 1 END) = 2
),
c AS (   -- customers: keep only those with 1st and 2nd preferences recorded, no preference higher than 3
    SELECT "CustomerID",
           MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS "Pref1",
           MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS "Pref2"
    FROM   "Musical_Preferences"
    GROUP  BY "CustomerID"
    HAVING MAX("PreferenceSeq") <= 3
       AND COUNT(CASE WHEN "PreferenceSeq" IN (1,2) THEN 1 END) = 2
)
SELECT DISTINCT en."EntStageName",
                cu."CustLastName"
FROM   e
JOIN   c
       ON (e."Style1" = c."Pref1" AND e."Style2" = c."Pref2")   -- same order
       OR (e."Style1" = c."Pref2" AND e."Style2" = c."Pref1")   -- reverse order
JOIN   "Entertainers" AS en ON en."EntertainerID" = e."EntertainerID"
JOIN   "Customers"    AS cu ON cu."CustomerID"    = c."CustomerID"
ORDER  BY en."EntStageName", cu."CustLastName";