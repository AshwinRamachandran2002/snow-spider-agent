WITH
e_ranks AS (          -- strongest-to-weakest ranks for every entertainer
    SELECT  "EntertainerID",
            "StyleID",
            ROW_NUMBER() OVER (PARTITION BY "EntertainerID"
                               ORDER BY "StyleStrength" DESC, "StyleID") AS rn,
            COUNT(*)    OVER (PARTITION BY "EntertainerID")               AS e_cnt
    FROM    "Entertainer_Styles"
),
c_ranks AS (          -- preference ranks for every customer
    SELECT  "CustomerID",
            "StyleID",
            ROW_NUMBER() OVER (PARTITION BY "CustomerID"
                               ORDER BY "PreferenceSeq")                  AS rn,
            COUNT(*)    OVER (PARTITION BY "CustomerID")                  AS c_cnt
    FROM    "Musical_Preferences"
),

/* 1-2 match in the same order */
pairs_same AS (
    SELECT e1."EntertainerID", c1."CustomerID"
    FROM   e_ranks e1
    JOIN   e_ranks e2 ON e1."EntertainerID" = e2."EntertainerID" AND e2.rn = 2
    JOIN   c_ranks c1 ON e1."StyleID"     = c1."StyleID"         AND c1.rn = 1
    JOIN   c_ranks c2 ON c1."CustomerID"  = c2."CustomerID"      AND c2.rn = 2
    WHERE  e1.rn = 1
      AND  e2."StyleID" = c2."StyleID"
      AND  e1.e_cnt <= 3            -- entertainer has ≤ 3 strengths
      AND  c1.c_cnt <= 3            -- customer has ≤ 3 preferences
),

/* 1-2 match in reverse order */
pairs_rev AS (
    SELECT e1."EntertainerID", c1."CustomerID"
    FROM   e_ranks e1
    JOIN   e_ranks e2 ON e1."EntertainerID" = e2."EntertainerID" AND e2.rn = 2
    JOIN   c_ranks c1 ON e2."StyleID"     = c1."StyleID"         AND c1.rn = 1
    JOIN   c_ranks c2 ON c1."CustomerID"  = c2."CustomerID"      AND c2.rn = 2
    WHERE  e1.rn = 1
      AND  e1."StyleID" = c2."StyleID"
      AND  e1.e_cnt <= 3
      AND  c1.c_cnt <= 3
),

all_pairs AS (        -- union of both matching directions
    SELECT * FROM pairs_same
    UNION
    SELECT * FROM pairs_rev
)

SELECT DISTINCT
       ent."EntStageName"  AS "EntertainerStageName",
       cust."CustLastName" AS "CustomerLastName"
FROM   all_pairs  p
JOIN   "Entertainers" ent ON ent."EntertainerID" = p."EntertainerID"
JOIN   "Customers"   cust ON cust."CustomerID"   = p."CustomerID";