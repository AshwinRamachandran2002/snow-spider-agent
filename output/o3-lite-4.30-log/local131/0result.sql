SELECT
    s."StyleName" AS musical_style,
    COALESCE(SUM(CASE WHEN p."PreferenceSeq" = 1 THEN 1 ELSE 0 END),0) AS first_pref_count,
    COALESCE(SUM(CASE WHEN p."PreferenceSeq" = 2 THEN 1 ELSE 0 END),0) AS second_pref_count,
    COALESCE(SUM(CASE WHEN p."PreferenceSeq" = 3 THEN 1 ELSE 0 END),0) AS third_pref_count
FROM "Musical_Styles" AS s
LEFT JOIN "Musical_Preferences" AS p
       ON p."StyleID" = s."StyleID"
      AND p."PreferenceSeq" IN (1,2,3)
GROUP BY s."StyleName"
ORDER BY s."StyleName";