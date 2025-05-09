WITH matching_images AS (
    SELECT DISTINCT t."SOPInstanceUID"
    FROM "IDC"."IDC_V17"."DICOM_ALL" t,
         LATERAL FLATTEN(input => t."SpecimenDescriptionSequence") sds,
         LATERAL FLATTEN(input => sds.value:"SpecimenPreparationSequence") sps,
         LATERAL FLATTEN(input => sps.value:"SpecimenPreparationStepContentItemSequence") spscis,
         LATERAL FLATTEN(input => spscis.value:"ConceptNameCodeSequence") cncs,
         LATERAL FLATTEN(input => spscis.value:"ConceptCodeSequence") ccs
    WHERE t."Modality" = 'SM'
      AND t."collection_id" = 'tcga_brca'
      AND (
          cncs.value:"CodeMeaning"::STRING ILIKE '%eosin%'
          OR ccs.value:"CodeMeaning"::STRING ILIKE '%eosin%'
          OR spscis.value:"TextValue"::STRING ILIKE '%eosin%'
      )
)
SELECT SUM(TRY_TO_NUMBER(t."NumberOfFrames")) AS "TotalFrames"
FROM "IDC"."IDC_V17"."DICOM_ALL" t
JOIN matching_images m ON t."SOPInstanceUID" = m."SOPInstanceUID";