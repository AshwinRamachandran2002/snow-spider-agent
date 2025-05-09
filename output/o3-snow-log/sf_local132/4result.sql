/*--------------------------------------------------------------
  Pairs of entertainers and customers
  – each has no more than three styles / preferences
  – the customer’s 1st & 2nd preferences match the
    entertainer’s 1st & 2nd strengths (in either order)
--------------------------------------------------------------*/
WITH
/* ----------  entertainers with style order --------------- */
e_rank AS (
    SELECT
        es."EntertainerID",
        es."StyleID",
        ROW_NUMBER() OVER (PARTITION BY es."EntertainerID"
                           ORDER BY es."StyleStrength" ASC)  AS rn,
        COUNT(*)    OVER (PARTITION BY es."EntertainerID")   AS cnt_styles
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINER_STYLES es
),
qualified_ent AS (
    SELECT
        "EntertainerID",
        MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS ent_style1,
        MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS ent_style2
    FROM e_rank
    WHERE cnt_styles <= 3           -- at most three strengths
    GROUP BY "EntertainerID"
    HAVING MAX(CASE WHEN rn = 2 THEN "StyleID" END) IS NOT NULL  -- need two styles
),

/* ----------  customers with preference order ------------- */
c_rank AS (
    SELECT
        mp."CustomerID",
        mp."StyleID",
        ROW_NUMBER() OVER (PARTITION BY mp."CustomerID"
                           ORDER BY mp."PreferenceSeq" ASC)  AS rn,
        COUNT(*)    OVER (PARTITION BY mp."CustomerID")      AS cnt_prefs
    FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.MUSICAL_PREFERENCES mp
),
qualified_cust AS (
    SELECT
        "CustomerID",
        MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS cust_style1,
        MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS cust_style2
    FROM c_rank
    WHERE cnt_prefs <= 3            -- at most three preferences
    GROUP BY "CustomerID"
    HAVING MAX(CASE WHEN rn = 2 THEN "StyleID" END) IS NOT NULL  -- need two prefs
)

/* ----------  final pairing -------------------------------- */
SELECT DISTINCT
       et."EntStageName",
       cu."CustLastName"
FROM qualified_ent  qe
JOIN qualified_cust qc
     ON (qe.ent_style1 = qc.cust_style1 AND qe.ent_style2 = qc.cust_style2)
     OR (qe.ent_style1 = qc.cust_style2 AND qe.ent_style2 = qc.cust_style1)
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.ENTERTAINERS et
     ON et."EntertainerID" = qe."EntertainerID"
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY.CUSTOMERS   cu
     ON cu."CustomerID"    = qc."CustomerID";