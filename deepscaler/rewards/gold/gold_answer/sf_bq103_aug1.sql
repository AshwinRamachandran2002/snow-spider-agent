-- Task: Count the number of genetic variants in the region between positions 55039447 and 55064852 on chromosome 1 using data from the gnomAD v3 version.
SELECT COUNT(*) AS num_variants
FROM "GNOMAD"."GNOMAD"."V3_GENOMES__CHR1"
WHERE "start_position" BETWEEN 55039447 AND 55064852;