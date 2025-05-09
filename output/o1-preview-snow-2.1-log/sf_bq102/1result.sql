SELECT DISTINCT t."start_position"
FROM GNOMAD.GNOMAD."V2_1_1_EXOMES__CHR17" t,
     LATERAL FLATTEN(input => t."alternate_bases") ab
WHERE t."reference_bases" = 'C'
  AND ab.value:"alt"::STRING = 'T'
  AND t."start_position" BETWEEN 41196312 AND 41322420;