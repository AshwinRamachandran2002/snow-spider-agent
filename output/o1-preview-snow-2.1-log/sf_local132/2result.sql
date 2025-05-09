WITH EntertainerTopTwoStyles AS (
    SELECT
        es."EntertainerID",
        es."StyleID"
    FROM
        "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINER_STYLES" es
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY es."EntertainerID"
            ORDER BY es."StyleStrength" DESC NULLS LAST
        ) <= 2
),
CustomerTopTwoPreferences AS (
    SELECT
        mp."CustomerID",
        mp."StyleID"
    FROM
        "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."MUSICAL_PREFERENCES" mp
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY mp."CustomerID"
            ORDER BY mp."PreferenceSeq" ASC NULLS LAST
        ) <= 2
),
MatchedPairs AS (
    SELECT
        ets."EntertainerID",
        ctp."CustomerID"
    FROM
        EntertainerTopTwoStyles ets
    INNER JOIN CustomerTopTwoPreferences ctp
        ON ets."StyleID" = ctp."StyleID"
    GROUP BY
        ets."EntertainerID",
        ctp."CustomerID"
    HAVING COUNT(DISTINCT ets."StyleID") = 2
)
SELECT
    e."EntStageName",
    c."CustLastName"
FROM
    MatchedPairs mp
JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."ENTERTAINERS" e
    ON mp."EntertainerID" = e."EntertainerID"
JOIN "ENTERTAINMENTAGENCY"."ENTERTAINMENTAGENCY"."CUSTOMERS" c
    ON mp."CustomerID" = c."CustomerID"
ORDER BY
    e."EntStageName",
    c."CustLastName";