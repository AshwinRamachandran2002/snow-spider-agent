SELECT DISTINCT
       ent."EntStageName" AS stage_name,
       cust."CustLastName" AS last_name
FROM (
        /* strongest two styles for each entertainer */
        SELECT  es."EntertainerID",
                MAX(CASE WHEN es.rn = 1 THEN es."StyleID" END) AS style1,
                MAX(CASE WHEN es.rn = 2 THEN es."StyleID" END) AS style2
        FROM (
            SELECT  "EntertainerID",
                    "StyleID",
                    ROW_NUMBER() OVER (PARTITION BY "EntertainerID"
                                       ORDER BY "StyleStrength" DESC) AS rn
            FROM    "Entertainer_Styles"
        ) es
        WHERE es.rn <= 2
        GROUP BY es."EntertainerID"
        HAVING COUNT(*) = 2                       -- need both first and second style
     ) e
JOIN (
        /* keep only entertainers that have up to three total styles */
        SELECT  "EntertainerID"
        FROM    "Entertainer_Styles"
        GROUP BY "EntertainerID"
        HAVING COUNT(*) <= 3
     ) ok_e  ON ok_e."EntertainerID" = e."EntertainerID"
JOIN "Entertainers" ent ON ent."EntertainerID" = e."EntertainerID"
JOIN (
        /* first two preferences for customers that have up to three preferences */
        SELECT  mp."CustomerID",
                MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS pref1,
                MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS pref2
        FROM    "Musical_Preferences" mp
        GROUP BY mp."CustomerID"
        HAVING COUNT(*) <= 3
     ) cp ON (e.style1 = cp.pref1 AND e.style2 = cp.pref2)
        OR (e.style1 = cp.pref2 AND e.style2 = cp.pref1)
JOIN "Customers" cust ON cust."CustomerID" = cp."CustomerID";