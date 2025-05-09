/*  Pairs every entertainer and customer (each having no more than three
    style strengths / musical preferences) whose first-and-second styles
    match one another, in the same or the reverse order.
*/
WITH ent_styles AS (          -- entertainers: keep first & second strengths
    SELECT
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS "Style1",
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS "Style2"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES
    GROUP BY "EntertainerID"
    HAVING COUNT(*) <= 3                        -- up to three strengths
       AND MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) IS NOT NULL
       AND MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) IS NOT NULL
),
cust_prefs AS (             -- customers: keep first & second preferences
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS "Pref1",
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS "Pref2"
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3                        -- up to three preferences
       AND MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) IS NOT NULL
       AND MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) IS NOT NULL
),
matched_pairs AS (          -- match first/second styles (either order)
    SELECT
        e."EntertainerID",
        c."CustomerID"
    FROM ent_styles e
    JOIN cust_prefs c
      ON ( (e."Style1" = c."Pref1" AND e."Style2" = c."Pref2")
        OR (e."Style1" = c."Pref2" AND e."Style2" = c."Pref1") )
)
SELECT
    et."EntStageName"   AS "StageName",
    cu."CustLastName"   AS "CustomerLastName"
FROM matched_pairs   mp
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINERS et
  ON mp."EntertainerID" = et."EntertainerID"
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.CUSTOMERS   cu
  ON mp."CustomerID"   = cu."CustomerID"
ORDER BY
    "StageName",
    "CustomerLastName";