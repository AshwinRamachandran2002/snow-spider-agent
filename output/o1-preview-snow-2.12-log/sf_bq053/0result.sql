SELECT
  UPPER(REPLACE(ts."fall_color", ' ', '')) AS "Fall_Color",
  SUM(COALESCE(t2015_counts."tree_count_2015", 0) - COALESCE(t1995_counts."tree_count_1995", 0)) AS "Total_Change"
FROM "NEW_YORK"."NEW_YORK"."TREE_SPECIES" ts
LEFT JOIN (
  SELECT UPPER("spc_latin") AS "species_name", COUNT(*) AS "tree_count_1995"
  FROM "NEW_YORK"."NEW_YORK"."TREE_CENSUS_1995"
  WHERE "spc_latin" IS NOT NULL AND "spc_latin" != '' AND "status" IS NOT NULL AND UPPER("status") != 'DEAD'
  GROUP BY UPPER("spc_latin")
) t1995_counts
  ON UPPER(ts."species_scientific_name") = t1995_counts."species_name"
LEFT JOIN (
  SELECT UPPER("spc_latin") AS "species_name", COUNT(*) AS "tree_count_2015"
  FROM "NEW_YORK"."NEW_YORK"."TREE_CENSUS_2015"
  WHERE "spc_latin" IS NOT NULL AND "spc_latin" != '' AND "status" IS NOT NULL AND UPPER("status") = 'ALIVE'
  GROUP BY UPPER("spc_latin")
) t2015_counts
  ON UPPER(ts."species_scientific_name") = t2015_counts."species_name"
GROUP BY UPPER(REPLACE(ts."fall_color", ' ', ''))
ORDER BY UPPER(REPLACE(ts."fall_color", ' ', ''));