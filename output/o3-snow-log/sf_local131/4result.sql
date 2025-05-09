SELECT
    ms."StyleID",
    ms."StyleName",
    SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "First_Pref_Count",
    SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "Second_Pref_Count",
    SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "Third_Pref_Count"
FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_STYLES"       ms
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES" mp
       ON ms."StyleID" = mp."StyleID"
GROUP BY
    ms."StyleID",
    ms."StyleName"
ORDER BY
    ms."StyleName";