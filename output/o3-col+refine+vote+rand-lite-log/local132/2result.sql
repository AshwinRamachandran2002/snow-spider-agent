SELECT DISTINCT
       e."EntStageName",
       c."CustLastName"
FROM "Entertainers" AS e
JOIN (
       /* entertainers with at most three style-strength rows */
       SELECT "EntertainerID",
              MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS "Style1",
              MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS "Style2",
              COUNT(*) AS "StyleCnt"
       FROM "Entertainer_Styles"
       GROUP BY "EntertainerID"
       HAVING "StyleCnt" <= 3
) AS es
  ON es."EntertainerID" = e."EntertainerID"
JOIN (
       /* customers with at most three musical-preference rows */
       SELECT "CustomerID",
              MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS "Pref1",
              MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS "Pref2",
              COUNT(*) AS "PrefCnt"
       FROM "Musical_Preferences"
       GROUP BY "CustomerID"
       HAVING "PrefCnt" <= 3
) AS mp
  /* match first & second styles in either order */
  ON (mp."Pref1" = es."Style1" AND mp."Pref2" = es."Style2")
   OR (mp."Pref1" = es."Style2" AND mp."Pref2" = es."Style1")
JOIN "Customers" AS c
  ON c."CustomerID" = mp."CustomerID";