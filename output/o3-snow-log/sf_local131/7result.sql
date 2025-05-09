SELECT 
    ms."StyleID",
    ms."StyleName",
    COALESCE(SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 END), 0) AS "FirstPreferenceCnt",
    COALESCE(SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 END), 0) AS "SecondPreferenceCnt",
    COALESCE(SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 END), 0) AS "ThirdPreferenceCnt"
FROM 
    ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_STYLES"   ms
LEFT JOIN 
    ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES" mp
    ON ms."StyleID" = mp."StyleID"
GROUP BY 
    ms."StyleID",
    ms."StyleName"
ORDER BY 
    ms."StyleName";