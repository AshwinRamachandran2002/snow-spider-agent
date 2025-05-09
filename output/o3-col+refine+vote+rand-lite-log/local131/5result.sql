SELECT
        ms."StyleName",
        SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "First_Pref",
        SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "Second_Pref",
        SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "Third_Pref"
FROM    "Musical_Styles"      AS ms
LEFT JOIN "Musical_Preferences" AS mp
          USING ("StyleID")
GROUP BY ms."StyleID", ms."StyleName"
ORDER BY ms."StyleName";