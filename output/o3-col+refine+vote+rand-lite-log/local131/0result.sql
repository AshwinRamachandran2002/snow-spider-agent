SELECT 
    ms."StyleName",
    SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "FirstPrefCount",
    SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "SecondPrefCount",
    SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "ThirdPrefCount"
FROM "Musical_Styles"      AS ms
LEFT JOIN "Musical_Preferences" AS mp
       ON mp."StyleID" = ms."StyleID"
GROUP BY ms."StyleName"
ORDER BY ms."StyleName";