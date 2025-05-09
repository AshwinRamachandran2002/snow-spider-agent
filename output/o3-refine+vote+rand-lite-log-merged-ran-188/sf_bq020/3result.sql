/* reference sequence with the highest overall variant density
   (variants from both VCFs per reference-base length) */
SELECT
       r."name" AS "reference_name"
FROM   "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_REFERENCE_201703" r
JOIN  (   /* total variants per reference sequence across both VCF tables */
          SELECT  COALESCE(t."reference_name", g."reference_name")                 AS "reference_name",
                  COALESCE(t."variant_count", 0) + COALESCE(g."variant_count", 0)  AS "total_variants"
          FROM  (
                    SELECT "reference_name", COUNT(*) AS "variant_count"
                    FROM   "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_TRANSCRIPTOME_201703"
                    GROUP BY "reference_name"
                ) t
          FULL JOIN
                (
                    SELECT "reference_name", COUNT(*) AS "variant_count"
                    FROM   "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_201703"
                    GROUP BY "reference_name"
                ) g
          ON t."reference_name" = g."reference_name"
     ) v
  ON r."name" = v."reference_name"
ORDER BY (v."total_variants" / NULLIF(r."length", 0)) DESC NULLS LAST
LIMIT 1;