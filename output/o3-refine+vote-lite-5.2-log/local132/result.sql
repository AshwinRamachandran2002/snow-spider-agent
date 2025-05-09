WITH
e_styles AS (
    SELECT
        "EntertainerID",
        "StyleID",
        ROW_NUMBER() OVER (PARTITION BY "EntertainerID" ORDER BY "StyleStrength") AS rn,
        COUNT(*)     OVER (PARTITION BY "EntertainerID")                     AS style_cnt
    FROM "Entertainer_Styles"
),
e_top AS (                  -- first and second strongest styles, only if ≤ 3 total
    SELECT
        "EntertainerID",
        MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS style1,
        MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS style2
    FROM e_styles
    WHERE style_cnt <= 3
    GROUP BY "EntertainerID"
    HAVING style1 IS NOT NULL AND style2 IS NOT NULL
),
c_prefs AS (
    SELECT
        "CustomerID",
        "StyleID",
        ROW_NUMBER() OVER (PARTITION BY "CustomerID" ORDER BY "PreferenceSeq") AS rn,
        COUNT(*)     OVER (PARTITION BY "CustomerID")                          AS pref_cnt
    FROM "Musical_Preferences"
),
c_top AS (                  -- first and second preferences, only if ≤ 3 total
    SELECT
        "CustomerID",
        MAX(CASE WHEN rn = 1 THEN "StyleID" END) AS style1,
        MAX(CASE WHEN rn = 2 THEN "StyleID" END) AS style2
    FROM c_prefs
    WHERE pref_cnt <= 3
    GROUP BY "CustomerID"
    HAVING style1 IS NOT NULL AND style2 IS NOT NULL
)
SELECT DISTINCT
       e."EntStageName",
       cst."CustLastName"
FROM        e_top           et
JOIN        "Entertainers"  e   ON e."EntertainerID" = et."EntertainerID"
JOIN        c_top           ct  ON (et.style1 = ct.style1 AND et.style2 = ct.style2)
                                 OR (et.style1 = ct.style2 AND et.style2 = ct.style1)
JOIN        "Customers"     cst ON cst."CustomerID" = ct."CustomerID"
ORDER BY    e."EntStageName",
            cst."CustLastName";