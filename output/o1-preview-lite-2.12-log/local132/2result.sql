SELECT DISTINCT e."EntStageName", c."CustLastName"
FROM "Entertainers" e
JOIN (
    SELECT "EntertainerID"
    FROM "Entertainer_Styles"
    GROUP BY "EntertainerID"
    HAVING COUNT(*) <= 3
) es_count ON e."EntertainerID" = es_count."EntertainerID"
JOIN "Entertainer_Styles" es1 ON e."EntertainerID" = es1."EntertainerID" AND es1."StyleStrength" = 1
JOIN "Entertainer_Styles" es2 ON e."EntertainerID" = es2."EntertainerID" AND es2."StyleStrength" = 2
JOIN (
    SELECT "CustomerID"
    FROM "Musical_Preferences"
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3
) mp_count ON 1=1
JOIN "Musical_Preferences" mp1 ON mp_count."CustomerID" = mp1."CustomerID" AND mp1."PreferenceSeq" = 1
JOIN "Musical_Preferences" mp2 ON mp1."CustomerID" = mp2."CustomerID" AND mp2."PreferenceSeq" = 2
JOIN "Customers" c ON mp1."CustomerID" = c."CustomerID"
WHERE 
    (mp1."StyleID" = es1."StyleID" AND mp2."StyleID" = es2."StyleID")
    OR
    (mp1."StyleID" = es2."StyleID" AND mp2."StyleID" = es1."StyleID");