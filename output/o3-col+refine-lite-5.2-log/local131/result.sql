SELECT
  ms."StyleName",
  SUM(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 ELSE 0 END) AS "first_pref_cnt",
  SUM(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 ELSE 0 END) AS "second_pref_cnt",
  SUM(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 ELSE 0 END) AS "third_pref_cnt"
FROM "Musical_Styles" AS ms
LEFT JOIN "Musical_Preferences" AS mp
  ON ms."StyleID" = mp."StyleID"
GROUP BY ms."StyleName"
ORDER BY ms."StyleName";