SELECT
    s."StyleID",
    s."StyleName",
    /* number of times the style is the 1st preference */
    SUM(CASE WHEN p."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "Pref_1_Count",
    /* number of times the style is the 2nd preference */
    SUM(CASE WHEN p."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "Pref_2_Count",
    /* number of times the style is the 3rd preference */
    SUM(CASE WHEN p."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "Pref_3_Count"
FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_STYLES"      AS s
LEFT JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES" AS p
       ON s."StyleID" = p."StyleID"
GROUP BY
    s."StyleID",
    s."StyleName"
ORDER BY
    s."StyleName";