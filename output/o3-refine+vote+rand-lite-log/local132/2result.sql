WITH e_raw AS (
    SELECT
        "EntertainerID",
        MAX(CASE WHEN "StyleStrength" = 1 THEN "StyleID" END) AS s1,
        MAX(CASE WHEN "StyleStrength" = 2 THEN "StyleID" END) AS s2,
        COUNT(*) AS cnt
    FROM "Entertainer_Styles"
    GROUP BY "EntertainerID"
),
e AS (            -- entertainers with ≤ 3 styles and both 1st & 2nd strengths present
    SELECT *
    FROM e_raw
    WHERE cnt <= 3
      AND s1 IS NOT NULL
      AND s2 IS NOT NULL
),
c_raw AS (
    SELECT
        "CustomerID",
        MAX(CASE WHEN "PreferenceSeq" = 1 THEN "StyleID" END) AS p1,
        MAX(CASE WHEN "PreferenceSeq" = 2 THEN "StyleID" END) AS p2,
        COUNT(*) AS cnt
    FROM "Musical_Preferences"
    GROUP BY "CustomerID"
),
c AS (            -- customers with ≤ 3 preferences and both 1st & 2nd prefs present
    SELECT *
    FROM c_raw
    WHERE cnt <= 3
      AND p1 IS NOT NULL
      AND p2 IS NOT NULL
)
SELECT DISTINCT
       en."EntStageName",
       cu."CustLastName"
FROM e
JOIN c
      ON (e.s1 = c.p1 AND e.s2 = c.p2)      -- same order
      OR (e.s1 = c.p2 AND e.s2 = c.p1)      -- reversed order
JOIN "Entertainers"  en ON en."EntertainerID" = e."EntertainerID"
JOIN "Customers"     cu ON cu."CustomerID"    = c."CustomerID"
ORDER BY en."EntStageName", cu."CustLastName";