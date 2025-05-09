SELECT
  ms."StyleName",
  COUNT(CASE WHEN mp."PreferenceSeq" = 1 THEN 1 END) AS "Preference1_Count",
  COUNT(CASE WHEN mp."PreferenceSeq" = 2 THEN 1 END) AS "Preference2_Count",
  COUNT(CASE WHEN mp."PreferenceSeq" = 3 THEN 1 END) AS "Preference3_Count"
FROM
  ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_STYLES ms
LEFT JOIN
  ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES mp
  ON ms."StyleID" = mp."StyleID"
GROUP BY
  ms."StyleName"
ORDER BY
  ms."StyleName";