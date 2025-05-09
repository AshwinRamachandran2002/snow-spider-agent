WITH EntertainersWithTopStyles AS (
    SELECT
        es_counts."EntertainerID",
        MAX(CASE WHEN es_rank."Rank" = 1 THEN es_rank."StyleID" END) AS "EntertainerFirstStyle",
        MAX(CASE WHEN es_rank."Rank" = 2 THEN es_rank."StyleID" END) AS "EntertainerSecondStyle"
    FROM (
        SELECT "EntertainerID", COUNT(*) AS "StyleCount"
        FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."ENTERTAINER_STYLES"
        GROUP BY "EntertainerID"
        HAVING COUNT(*) <= 3
    ) es_counts
    JOIN (
        SELECT
            "EntertainerID",
            "StyleID",
            ROW_NUMBER() OVER (
                PARTITION BY "EntertainerID"
                ORDER BY "StyleStrength" DESC NULLS LAST
            ) AS "Rank"
        FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."ENTERTAINER_STYLES"
    ) es_rank
    ON es_counts."EntertainerID" = es_rank."EntertainerID"
    WHERE es_rank."Rank" <= 2
    GROUP BY es_counts."EntertainerID"
),
CustomersWithTopPreferences AS (
    SELECT
        mp_counts."CustomerID",
        MAX(CASE WHEN mp."PreferenceSeq" = 1 THEN mp."StyleID" END) AS "CustomerFirstPreference",
        MAX(CASE WHEN mp."PreferenceSeq" = 2 THEN mp."StyleID" END) AS "CustomerSecondPreference"
    FROM (
        SELECT "CustomerID", COUNT(*) AS "PreferenceCount"
        FROM ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES"
        GROUP BY "CustomerID"
        HAVING COUNT(*) <= 3
    ) mp_counts
    JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."MUSICAL_PREFERENCES" mp
    ON mp_counts."CustomerID" = mp."CustomerID"
    WHERE mp."PreferenceSeq" IN (1, 2)
    GROUP BY mp_counts."CustomerID"
)
SELECT DISTINCT e."EntStageName", c."CustLastName"
FROM EntertainersWithTopStyles es
JOIN CustomersWithTopPreferences cp
    ON (
        (es."EntertainerFirstStyle" = cp."CustomerFirstPreference" AND es."EntertainerSecondStyle" = cp."CustomerSecondPreference")
        OR
        (es."EntertainerFirstStyle" = cp."CustomerSecondPreference" AND es."EntertainerSecondStyle" = cp."CustomerFirstPreference")
    )
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."ENTERTAINERS" e
    ON es."EntertainerID" = e."EntertainerID"
JOIN ENTERTAINMENTAGENCY.ENTERTAINMENTAGENCY."CUSTOMERS" c
    ON cp."CustomerID" = c."CustomerID"
LIMIT 100;