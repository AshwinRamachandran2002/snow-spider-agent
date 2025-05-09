WITH CustomerPrefs AS (
    SELECT
        mp."CustomerID",
        MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS Pref1,
        MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS Pref2
    FROM "Musical_Preferences" mp
    GROUP BY mp."CustomerID"
    HAVING COUNT(*) <= 3                      -- customer has no more than 3 preferences
           AND Pref1 IS NOT NULL              -- has 1st preference
           AND Pref2 IS NOT NULL              -- has 2nd preference
), EntStyles AS (
    SELECT
        es."EntertainerID",
        MAX(CASE WHEN es."StyleStrength" = 1 THEN es."StyleID" END) AS Str1,
        MAX(CASE WHEN es."StyleStrength" = 2 THEN es."StyleID" END) AS Str2
    FROM "Entertainer_Styles" es
    GROUP BY es."EntertainerID"
    HAVING COUNT(*) <= 3                      -- entertainer has no more than 3 strengths
           AND Str1 IS NOT NULL               -- has 1st strength
           AND Str2 IS NOT NULL               -- has 2nd strength
)
SELECT DISTINCT
       e."EntStageName",
       c."CustLastName"
FROM EntStyles  es
JOIN "Entertainers" e ON e."EntertainerID" = es."EntertainerID"
CROSS JOIN CustomerPrefs cp
JOIN "Customers"  c ON c."CustomerID" = cp."CustomerID"
WHERE (cp.Pref1 = es.Str1 AND cp.Pref2 = es.Str2)   -- same order
   OR (cp.Pref1 = es.Str2 AND cp.Pref2 = es.Str1);  -- reversed order