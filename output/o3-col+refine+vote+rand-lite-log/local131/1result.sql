SELECT
    s."StyleName",
    SUM(CASE WHEN p."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "FirstPreferenceCnt",
    SUM(CASE WHEN p."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "SecondPreferenceCnt",
    SUM(CASE WHEN p."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "ThirdPreferenceCnt"
FROM   "Musical_Styles"      AS s
LEFT JOIN "Musical_Preferences" AS p
       ON s."StyleID" = p."StyleID"
GROUP  BY s."StyleID", s."StyleName"
ORDER  BY s."StyleName";