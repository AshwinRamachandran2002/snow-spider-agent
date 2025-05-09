SELECT
    t."reference_bases",
    MIN(t."start_position")                         AS "min_start_position",
    MAX(t."start_position")                         AS "max_start_position",
    COUNT(*)                                        AS "row_count",
    ROUND(100.0 * COUNT(*) / total.cnt, 4)          AS "row_percentage"
FROM "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" t,
     ( SELECT COUNT(*) AS cnt
       FROM "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220" ) total
WHERE t."reference_bases" IN ('AT', 'TA')
GROUP BY t."reference_bases", total.cnt
ORDER BY t."reference_bases";