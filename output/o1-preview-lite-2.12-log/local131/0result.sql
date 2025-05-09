SELECT
    ms."StyleID",
    ms."StyleName",
    SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "Pref1_Count",
    SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "Pref2_Count",
    SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "Pref3_Count"
FROM
    "Musical_Styles" ms
LEFT JOIN
    "Musical_Preferences" mp
ON
    ms."StyleID" = mp."StyleID"
GROUP BY
    ms."StyleID", ms."StyleName"
ORDER BY
    ms."StyleID";