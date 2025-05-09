WITH LabelCounts AS (
  SELECT f.value:"description"::STRING AS "label", COUNT(DISTINCT t."object_id") AS "global_artwork_count"
  FROM "THE_MET"."THE_MET"."VISION_API_DATA" t,
  LATERAL FLATTEN(input => t."labelAnnotations") f
  GROUP BY "label"
  HAVING COUNT(DISTINCT t."object_id") >= 50
),
PeriodLabelCounts AS (
  SELECT o."period", f.value:"description"::STRING AS "label", COUNT(DISTINCT t."object_id") AS "artwork_count"
  FROM "THE_MET"."THE_MET"."VISION_API_DATA" t
  JOIN "THE_MET"."THE_MET"."OBJECTS" o ON t."object_id" = o."object_id",
  LATERAL FLATTEN(input => t."labelAnnotations") f
  WHERE f.value:"description"::STRING IN (SELECT "label" FROM LabelCounts)
  GROUP BY o."period", "label"
),
RankedLabels AS (
  SELECT "period", "label", "artwork_count",
  ROW_NUMBER() OVER (PARTITION BY "period" ORDER BY "artwork_count" DESC NULLS LAST, "label") AS "rank"
  FROM PeriodLabelCounts
)
SELECT "period" AS "Period", "label" AS "Label", "artwork_count" AS "Count"
FROM RankedLabels
WHERE "rank" <= 3
ORDER BY "Period" NULLS LAST, "rank";