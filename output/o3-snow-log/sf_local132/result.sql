WITH ent_styles AS (   /* entertainers that have 1st & 2nd strongest styles and no more than three total */
    SELECT
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS style1,
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS style2
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES
    GROUP BY "EntertainerID"
    HAVING COUNT(*) <= 3                                   /* up-to-three styles              */
       AND MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) IS NOT NULL  /* needs rank 1 */
       AND MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) IS NOT NULL  /* needs rank 2 */
),
cust_prefs AS (   /* customers that have 1st & 2nd preferences and no more than three total */
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS pref1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS pref2
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    GROUP BY "CustomerID"
    HAVING COUNT(*) <= 3                                   /* up-to-three preferences         */
       AND MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) IS NOT NULL  /* needs #1  */
       AND MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) IS NOT NULL  /* needs #2  */
)

SELECT DISTINCT
       e."EntStageName",
       c."CustLastName"
FROM ent_styles        es
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINERS  e
     ON e."EntertainerID" = es."EntertainerID"
JOIN cust_prefs        cp
     ON  (cp.pref1 = es.style1 AND cp.pref2 = es.style2)   /* same order */
      OR (cp.pref1 = es.style2 AND cp.pref2 = es.style1)   /* reverse order */
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.CUSTOMERS    c
     ON c."CustomerID" = cp."CustomerID";