-- Task: About the refined human genetic variations collected in phase 3 on 2015-02-20, I want to find the minimum and maximum start positions, and total counts for reference bases 'AT' and 'TA'.
SELECT
    "reference_bases",
    MIN("start_position") AS "min_start_position",
    MAX("start_position") AS "max_start_position",
    COUNT(1) AS "total_count"
FROM
    "HUMAN_GENOME_VARIANTS"."HUMAN_GENOME_VARIANTS"."_1000_GENOMES_PHASE_3_OPTIMIZED_SCHEMA_VARIANTS_20150220"
WHERE
    "reference_bases" IN ('AT', 'TA')
GROUP BY
    "reference_bases";