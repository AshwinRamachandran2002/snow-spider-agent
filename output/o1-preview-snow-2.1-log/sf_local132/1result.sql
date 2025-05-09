SELECT DISTINCT ent."EntStageName", cust."CustLastName"
FROM (
    SELECT ms."EntertainerID", ms."CustomerID"
    FROM (
        SELECT e."EntertainerID", c."CustomerID", e."StyleID"
        FROM "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINER_STYLES" e
        JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_PREFERENCES" c
            ON e."StyleID" = c."StyleID"
        WHERE e."StyleStrength" IN (1, 2)
          AND c."PreferenceSeq" IN (1, 2)
    ) ms
    GROUP BY ms."EntertainerID", ms."CustomerID"
    HAVING COUNT(DISTINCT ms."StyleID") = 2
) mc
JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINERS" ent
  ON mc."EntertainerID" = ent."EntertainerID"
JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."CUSTOMERS" cust
  ON mc."CustomerID" = cust."CustomerID";