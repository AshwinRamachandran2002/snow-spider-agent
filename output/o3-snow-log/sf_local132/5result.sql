WITH entertainer_style_counts AS (      -- entertainers that have 3 or fewer styles
    SELECT "EntertainerID",
           COUNT(DISTINCT "StyleID") AS style_cnt
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES
    GROUP BY "EntertainerID"
    HAVING style_cnt <= 3
),
ent_styles_ranked AS (                  -- rank styles by strength
    SELECT es."EntertainerID",
           es."StyleID",
           ROW_NUMBER() OVER (PARTITION BY es."EntertainerID"
                              ORDER BY es."StyleStrength" DESC, es."StyleID") AS rn
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES es
    JOIN entertainer_style_counts ec
      ON ec."EntertainerID" = es."EntertainerID"
),
ent_styles_top2 AS (                    -- grab the top-two styles
    SELECT "EntertainerID",
           MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS ent_style1,
           MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS ent_style2
    FROM ent_styles_ranked
    WHERE rn <= 2
    GROUP BY "EntertainerID"
    HAVING COUNT(*) = 2                 -- be sure we actually have two styles
),
customer_pref_counts AS (               -- customers that have 3 or fewer prefs
    SELECT "CustomerID",
           COUNT(DISTINCT "StyleID") AS pref_cnt
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES
    GROUP BY "CustomerID"
    HAVING pref_cnt <= 3
),
cust_prefs_ranked AS (                  -- rank customer preferences
    SELECT mp."CustomerID",
           mp."StyleID",
           ROW_NUMBER() OVER (PARTITION BY mp."CustomerID"
                              ORDER BY mp."PreferenceSeq") AS rn
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES mp
    JOIN customer_pref_counts cp
      ON cp."CustomerID" = mp."CustomerID"
),
cust_prefs_top2 AS (                    -- first two preferences
    SELECT "CustomerID",
           MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS cust_pref1,
           MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS cust_pref2
    FROM cust_prefs_ranked
    WHERE rn <= 2
    GROUP BY "CustomerID"
    HAVING COUNT(*) = 2
),
matched_pairs AS (                      -- match 1&2 or 2&1
    SELECT e."EntertainerID",
           c."CustomerID"
    FROM ent_styles_top2 e
    JOIN cust_prefs_top2 c
      ON (e.ent_style1 = c.cust_pref1 AND e.ent_style2 = c.cust_pref2)
       OR (e.ent_style1 = c.cust_pref2 AND e.ent_style2 = c.cust_pref1)
)
SELECT DISTINCT en."EntStageName",
                cu."CustLastName"
FROM matched_pairs  p
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINERS en
     ON en."EntertainerID" = p."EntertainerID"
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.CUSTOMERS   cu
     ON cu."CustomerID"   = p."CustomerID"
ORDER BY en."EntStageName", cu."CustLastName";