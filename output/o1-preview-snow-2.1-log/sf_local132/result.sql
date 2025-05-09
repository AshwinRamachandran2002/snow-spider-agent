WITH EntertainerTopStyles AS (
    SELECT
        es."EntertainerID",
        es."StyleID"
    FROM (
        SELECT
            es."EntertainerID",
            es."StyleID",
            ROW_NUMBER() OVER (
                PARTITION BY es."EntertainerID"
                ORDER BY es."StyleStrength" DESC NULLS LAST, es."StyleID" ASC
            ) AS RN
        FROM
            "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINER_STYLES" es
    ) es
    WHERE
        es.RN <= 2
),
CustomerTopPreferences AS (
    SELECT
        mp."CustomerID",
        mp."StyleID"
    FROM (
        SELECT
            mp."CustomerID",
            mp."StyleID",
            ROW_NUMBER() OVER (
                PARTITION BY mp."CustomerID"
                ORDER BY mp."PreferenceSeq" ASC NULLS LAST, mp."StyleID" ASC
            ) AS RN
        FROM
            "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_PREFERENCES" mp
            WHERE
                mp."PreferenceSeq" IN (1, 2)
        ) mp
    WHERE
        mp.RN <= 2
),
EntertainerCustomerMatches AS (
    SELECT
        ets."EntertainerID",
        ctp."CustomerID",
        COUNT(DISTINCT ets."StyleID") AS MatchingStyleCount
    FROM
        EntertainerTopStyles ets
        JOIN CustomerTopPreferences ctp ON ets."StyleID" = ctp."StyleID"
    GROUP BY
        ets."EntertainerID",
        ctp."CustomerID"
    HAVING
        MatchingStyleCount = 2
)
SELECT
    e."EntStageName",
    c."CustLastName"
FROM
    EntertainerCustomerMatches ecm
    JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINERS" e ON ecm."EntertainerID" = e."EntertainerID"
    JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."CUSTOMERS" c ON ecm."CustomerID" = c."CustomerID";