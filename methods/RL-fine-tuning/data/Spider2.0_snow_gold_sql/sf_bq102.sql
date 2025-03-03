SELECT DISTINCT t."start_position"
FROM "GNOMAD"."GNOMAD"."V2_1_1_EXOMES__CHR17" t,
     LATERAL FLATTEN(input => t."alternate_bases") ab
WHERE
  t."start_position" BETWEEN 43044295 AND 43125482 AND
  t."reference_bases" = 'C' AND
  ab.value:"alt"::STRING = 'T' AND
  t."variant_type" = 'snv';