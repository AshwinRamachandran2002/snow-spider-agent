SELECT
    s."StyleID",
    s."StyleName",
    SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "FirstPrefCount",
    SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "SecondPrefCount",
    SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "ThirdPrefCount"
FROM "Musical_Styles"        AS s
LEFT JOIN "Musical_Preferences" AS mp
       ON s."StyleID" = mp."StyleID"
GROUP BY
    s."StyleID",
    s."StyleName"
ORDER BY
    s."StyleName";