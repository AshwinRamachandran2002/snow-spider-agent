WITH
-- customers that have at most three musical preferences
cust AS (
    SELECT  mp.CustomerID,
            MAX(CASE WHEN mp.PreferenceSeq = 1 THEN mp.StyleID END) AS pref1,
            MAX(CASE WHEN mp.PreferenceSeq = 2 THEN mp.StyleID END) AS pref2,
            COUNT(*) AS pref_cnt
    FROM    Musical_Preferences AS mp
    GROUP BY mp.CustomerID
    HAVING  pref_cnt <= 3               -- no more than three preferences
        AND pref1 IS NOT NULL           -- must have a 1st preference
        AND pref2 IS NOT NULL           -- must have a 2nd preference
),
-- entertainers that have at most three style strengths
ent AS (
    SELECT  es.EntertainerID,
            MAX(CASE WHEN es.StyleStrength = 1 THEN es.StyleID END) AS sty1,
            MAX(CASE WHEN es.StyleStrength = 2 THEN es.StyleID END) AS sty2,
            COUNT(*) AS sty_cnt
    FROM    Entertainer_Styles AS es
    GROUP BY es.EntertainerID
    HAVING  sty_cnt <= 3                -- no more than three style strengths
        AND sty1 IS NOT NULL            -- must have a 1st strength
        AND sty2 IS NOT NULL            -- must have a 2nd strength
)
SELECT DISTINCT
       e2."EntStageName",
       c2."CustLastName"
FROM       ent AS e
JOIN       cust AS c
       ON (c.pref1 = e.sty1 AND c.pref2 = e.sty2)   -- same order
       OR (c.pref1 = e.sty2 AND c.pref2 = e.sty1)   -- reverse order
JOIN       Entertainers AS e2 ON e2.EntertainerID = e.EntertainerID
JOIN       Customers    AS c2 ON c2.CustomerID     = c.CustomerID;