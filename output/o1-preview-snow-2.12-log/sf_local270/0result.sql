SELECT
  "top_pack"."name" AS "Container_Name",
  "item_pack"."name" AS "Item_Name"
FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS "top_pack"
JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS "top_rel"
  ON "top_pack"."id" = "top_rel"."packaging_id"
LEFT JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS "mid_pack"
  ON "top_rel"."contains_id" = "mid_pack"."id"
LEFT JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS "mid_rel"
  ON "mid_pack"."id" = "mid_rel"."packaging_id"
LEFT JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS "bottom_pack"
  ON "mid_rel"."contains_id" = "bottom_pack"."id"
LEFT JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" AS "bottom_rel"
  ON "bottom_pack"."id" = "bottom_rel"."packaging_id"
LEFT JOIN "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" AS "item_pack"
  ON COALESCE("bottom_rel"."contains_id", "mid_rel"."contains_id", "top_rel"."contains_id") = "item_pack"."id"
WHERE "top_pack"."id" NOT IN (
  SELECT DISTINCT "contains_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
)
AND "item_pack"."id" NOT IN (
  SELECT DISTINCT "packaging_id" FROM "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS"
)
GROUP BY "top_pack"."name", "item_pack"."name"
HAVING SUM("top_rel"."qty" * COALESCE("mid_rel"."qty", 1) * COALESCE("bottom_rel"."qty", 1)) > 500