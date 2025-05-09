WITH cust_pref AS (
    SELECT  mp.CustomerID,
            MAX(CASE WHEN mp.PreferenceSeq = 1 THEN mp.StyleID END) AS pref1,
            MAX(CASE WHEN mp.PreferenceSeq = 2 THEN mp.StyleID END) AS pref2,
            COUNT(*) AS pref_cnt
    FROM    Musical_Preferences AS mp
    GROUP BY mp.CustomerID
    HAVING  pref_cnt <= 3
       AND  pref1 IS NOT NULL
       AND  pref2 IS NOT NULL
),
ent_styles AS (
    SELECT  es.EntertainerID,
            MAX(CASE WHEN es.StyleStrength = 1 THEN es.StyleID END) AS style1,
            MAX(CASE WHEN es.StyleStrength = 2 THEN es.StyleID END) AS style2,
            COUNT(*) AS style_cnt
    FROM    Entertainer_Styles AS es
    GROUP BY es.EntertainerID
    HAVING  style_cnt <= 3
       AND  style1 IS NOT NULL
       AND  style2 IS NOT NULL
)
SELECT DISTINCT
       en.EntStageName,
       cu.CustLastName
FROM       ent_styles  AS est
JOIN       Entertainers AS en ON en.EntertainerID = est.EntertainerID
JOIN       cust_pref    AS cp
JOIN       Customers    AS cu ON cu.CustomerID = cp.CustomerID
WHERE (cp.pref1 = est.style1 AND cp.pref2 = est.style2)
   OR (cp.pref1 = est.style2 AND cp.pref2 = est.style1);