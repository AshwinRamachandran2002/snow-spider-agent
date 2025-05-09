SELECT DISTINCT e."EntStageName", c."CustLastName"
FROM "Entertainers" e
JOIN (
    SELECT "EntertainerID"
    FROM "Entertainer_Styles"
    GROUP BY "EntertainerID"
    HAVING COUNT(*) <= 3
) e_limited ON e."EntertainerID" = e_limited."EntertainerID"
JOIN "Entertainer_Styles" es1 ON e."EntertainerID" = es1."EntertainerID" AND es1."StyleStrength" = 1
JOIN "Entertainer_Styles" es2 ON e."EntertainerID" = es2."EntertainerID" AND es2."StyleStrength" = 2
JOIN (
    SELECT "CustomerID"
    FROM "Musical_Preferences"
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3
) c_limited ON 1=1
JOIN "Musical_Preferences" mp1 ON mp1."CustomerID" = c_limited."CustomerID" AND mp1."PreferenceSeq" = 1
JOIN "Musical_Preferences" mp2 ON mp2."CustomerID" = mp1."CustomerID" AND mp2."PreferenceSeq" = 2
JOIN "Customers" c ON c."CustomerID" = mp1."CustomerID"
WHERE (es1."StyleID" = mp1."StyleID" AND es2."StyleID" = mp2."StyleID")
   OR (es1."StyleID" = mp2."StyleID" AND es2."StyleID" = mp1."StyleID");