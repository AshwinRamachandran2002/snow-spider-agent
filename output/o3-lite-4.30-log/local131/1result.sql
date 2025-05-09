SELECT
    ms."StyleName"                                                AS musical_style,
    SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END)       AS first_pref_count,
    SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END)       AS second_pref_count,
    SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END)       AS third_pref_count
FROM "Musical_Styles" AS ms
LEFT JOIN "Musical_Preferences" AS mp
       ON mp."StyleID" = ms."StyleID"
GROUP BY ms."StyleName"
ORDER BY ms."StyleName";