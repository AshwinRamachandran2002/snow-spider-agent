SELECT DISTINCT e."EntStageName", c."CustLastName"
FROM "Customers" AS c
JOIN "Musical_Preferences" AS mp1 ON c."CustomerID" = mp1."CustomerID" AND mp1."PreferenceSeq" = 1
JOIN "Musical_Preferences" AS mp2 ON c."CustomerID" = mp2."CustomerID" AND mp2."PreferenceSeq" = 2
JOIN "Entertainer_Styles" AS es1 ON es1."StyleStrength" = 1
JOIN "Entertainer_Styles" AS es2 ON es2."StyleStrength" = 2
JOIN "Entertainers" AS e ON es1."EntertainerID" = e."EntertainerID" AND es2."EntertainerID" = e."EntertainerID"
WHERE 
    (
        (mp1."StyleID" = es1."StyleID" AND mp2."StyleID" = es2."StyleID")
        OR
        (mp1."StyleID" = es2."StyleID" AND mp2."StyleID" = es1."StyleID")
    )