SELECT 
       s."StyleName",
       COALESCE(SUM(CASE WHEN p."PreferenceSeq" = 1 THEN 1 ELSE 0 END), 0) AS "First_Preference_Count",
       COALESCE(SUM(CASE WHEN p."PreferenceSeq" = 2 THEN 1 ELSE 0 END), 0) AS "Second_Preference_Count",
       COALESCE(SUM(CASE WHEN p."PreferenceSeq" = 3 THEN 1 ELSE 0 END), 0) AS "Third_Preference_Count"
FROM   ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_STYLES"      s
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES" p
       ON s."StyleID" = p."StyleID"
GROUP  BY s."StyleName"
ORDER  BY s."StyleName";