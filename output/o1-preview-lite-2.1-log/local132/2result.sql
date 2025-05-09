WITH EntertainerTopStyles AS (
    SELECT es1."EntertainerID", es1."StyleID"
    FROM "Entertainer_Styles" es1
    WHERE (
        SELECT COUNT(DISTINCT es2."StyleStrength")
        FROM "Entertainer_Styles" es2
        WHERE es2."EntertainerID" = es1."EntertainerID"
          AND es2."StyleStrength" > es1."StyleStrength"
    ) < 2
),
CustomerTopPreferences AS (
    SELECT mp."CustomerID", mp."StyleID"
    FROM "Musical_Preferences" mp
    WHERE mp."PreferenceSeq" IN (1, 2)
)
SELECT DISTINCT e."EntStageName", c."CustLastName"
FROM EntertainerTopStyles ets
JOIN CustomerTopPreferences ctp ON ets."StyleID" = ctp."StyleID"
JOIN "Entertainers" e ON ets."EntertainerID" = e."EntertainerID"
JOIN "Customers" c ON ctp."CustomerID" = c."CustomerID"
GROUP BY e."EntertainerID", c."CustomerID"
HAVING COUNT(DISTINCT ets."StyleID") = 2;