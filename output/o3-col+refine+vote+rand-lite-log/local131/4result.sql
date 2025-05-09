SELECT
    ms."StyleName",
    SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "FirstPref",
    SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "SecondPref",
    SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "ThirdPref"
FROM   "Musical_Styles"      AS ms
LEFT JOIN "Musical_Preferences" AS mp
       ON mp."StyleID" = ms."StyleID"
GROUP BY ms."StyleID", ms."StyleName";