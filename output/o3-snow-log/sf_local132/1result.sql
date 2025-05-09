/*---------------------------------------------------------------
  Pairs of entertainers and customers whose first two
  style strengths / preferences match (in either order),
  provided that each party lists no more than three styles.
----------------------------------------------------------------*/

WITH
/*------- 1.  Rank entertainer styles & keep those with ≤3 -------*/
e_styles AS (
    SELECT
        es."EntertainerID",
        es."StyleID",
        es."StyleStrength",
        ROW_NUMBER() OVER (
            PARTITION BY es."EntertainerID"
            ORDER BY es."StyleStrength" DESC, es."StyleID"
        )                             AS rn,
        COUNT(*) OVER (
            PARTITION BY es."EntertainerID"
        )                             AS style_cnt
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES es
),
e_top AS (
    SELECT
        "EntertainerID",
        MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS style1,
        MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS style2
    FROM e_styles
    WHERE style_cnt <= 3
    GROUP BY "EntertainerID"
    HAVING COUNT(CASE WHEN rn <= 2 THEN 1 END) = 2      -- need at least two styles
),

/*------- 2.  Grab customers’ first two style preferences -------*/
c_pref AS (
    SELECT
        mp."CustomerID",
        mp."StyleID",
        mp."PreferenceSeq",
        COUNT(*) OVER (
            PARTITION BY mp."CustomerID"
        )                             AS pref_cnt
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES mp
),
c_top AS (
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS style1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS style2
    FROM c_pref
    WHERE pref_cnt <= 3
    GROUP BY "CustomerID"
    HAVING COUNT(CASE WHEN "PreferenceSeq" IN (1,2) THEN 1 END) = 2   -- need first two prefs
)

/*------- 3.  Match first two styles (same order or reversed) ----*/
SELECT DISTINCT
       ent."EntStageName",
       cust."CustLastName"
FROM   c_top  c
JOIN   e_top  e
       ON (e.style1 = c.style1 AND e.style2 = c.style2)
       OR (e.style1 = c.style2 AND e.style2 = c.style1)
JOIN   ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINERS ent
       ON ent."EntertainerID" = e."EntertainerID"
JOIN   ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.CUSTOMERS  cust
       ON cust."CustomerID" = c."CustomerID";