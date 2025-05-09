SELECT
       s."StyleID",
       s."StyleName",
       SUM(CASE WHEN p."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "Pref1_Count",
       SUM(CASE WHEN p."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "Pref2_Count",
       SUM(CASE WHEN p."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "Pref3_Count"
FROM "Musical_Styles" AS s
LEFT JOIN "Musical_Preferences" AS p
       ON p."StyleID" = s."StyleID"
GROUP BY
       s."StyleID",
       s."StyleName"
ORDER BY
       s."StyleID";