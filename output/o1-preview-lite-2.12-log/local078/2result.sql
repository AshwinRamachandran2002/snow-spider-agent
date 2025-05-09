WITH max_compositions AS (
  SELECT
    im."interest_id",
    imap."interest_name" AS "Interest_Name",
    im."month_year" AS "Time(MM-YYYY)",
    ROUND(im."composition", 4) AS "Composition_Value"
  FROM "interest_metrics" AS im
  JOIN (
    SELECT
      "interest_id",
      MAX("composition") AS "max_comp"
    FROM "interest_metrics"
    WHERE "interest_id" IS NOT NULL
    GROUP BY "interest_id"
  ) AS mc ON im."interest_id" = mc."interest_id" AND im."composition" = mc."max_comp"
  JOIN "interest_map" AS imap ON im."interest_id" = imap."id"
),
top_10 AS (
  SELECT * FROM max_compositions
  ORDER BY "Composition_Value" DESC
  LIMIT 10
),
bottom_10 AS (
  SELECT * FROM max_compositions
  ORDER BY "Composition_Value" ASC
  LIMIT 10
)
SELECT "Time(MM-YYYY)", "Interest_Name", "Composition_Value" FROM top_10
UNION ALL
SELECT "Time(MM-YYYY)", "Interest_Name", "Composition_Value" FROM bottom_10
ORDER BY "Composition_Value" DESC;