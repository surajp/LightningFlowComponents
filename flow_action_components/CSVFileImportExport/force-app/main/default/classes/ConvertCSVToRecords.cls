/************************************************************

*** @date 06/2021
*** @description Invocable action to convert data from a CSV file to records of an SObject with matching fields. 
*** 
**/

public with sharing class ConvertCSVToRecords {
  private static Map<SObjectType, Map<String, Schema.SObjectField>> sobjFieldsMap = new Map<SObjectType, Map<String, Schema.SObjectField>>();

  @InvocableMethod(label='Convert CSV File to Records')
  public static Response[] convert(Request[] inputs) {
    Response[] responseList = new List<Response>{};

    for (Request curInput : inputs) {
      if (curInput.contentDocumentId == null && curInput.contentDocumentIdList == null) {
        throw new FlowCustomException(
          'You need to provide either a single ContentDocument Id OR a list of ContentDocumentIds as inputs to this Flow action.'
        );
      } else {
        if (curInput.contentDocumentIdList == null)
          curInput.contentDocumentIdList = new List<Id>();
        // Easiest to just combine the inputs for processing
        if (curInput.contentDocumentId != null)
          curInput.contentDocumentIdList.add(curInput.contentDocumentId);
      }

      for (String curContentDocumentId : curInput.contentDocumentIdList) {
        String csvStringContent = getCSVStringContent(curContentDocumentId);
        String headerRow = csvStringContent.substring(0, csvStringContent.indexOf('\n'));
        String[] fields = headerRow.split(','); //Gives all the API names of the fields from the 1st CSV row

        Map<String, Schema.DisplayType> fieldToFieldTypeMap = new Map<String, Schema.DisplayType>();
        SObjectType sObjType = getSObjectType(curInput.objectApiName);
        initFieldTypeMap(sObjType, fields, fieldToFieldTypeMap);

        Response output = new Response();
        output.convertedCSVRows = new List<SObject>{};
        CSVColIterator rowIterator = new CSVColIterator(csvStringContent)
          .setColDelimiter('\n')
          .setPreserveTextQualifier(true);
        rowIterator.next(); //skip header row
        while (rowIterator.hasNext()) {
          String row = rowIterator.next();
          if (String.isBlank(row)) {
            continue;
          }
          System.debug('>>> row ' + row);
          SObject obj = sObjType.newSObject();
          CSVColIterator colIterator = new CSVColIterator(row);
          Integer colIndex = 0;
          while (colIterator.hasNext()) {
            String currentColValue = colIterator.next().trim();
            String currentField = fields[colIndex++];
            Schema.DisplayType currFieldType = fieldToFieldTypeMap.get(currentField);
            if (curInput.setNullValues == null)
              curInput.setNullValues = false;
            setSObjectField(obj, currentField, currFieldType, currentColValue, curInput.setNullValues);
          }

          output.convertedCSVRows.add(obj);
        }
        responseList.add(output);
      }
    }
    return responseList;
  }

  private static List<Id> getContentDocIds(List<Request> inputs) {
    List<Id> contentDocIds = new List<Id>();
    for (Request req : inputs) {
      if (req.ContentDocumentIdList != null) {
        contentDocIds.addAll(req.ContentDocumentIdList);
      }
      if (req.ContentDocumentId != null) {
        contentDocIds.add(req.ContentDocumentId);
      }
    }
    return contentDocIds;
  }

  private static SObjectType getSObjectType(String objectApiName) {
    return ((SObject) Type.forName(objectApiName).newInstance()).getSObjectType();
  }

  private static String getCSVStringContent(Id curContentDocumentId) {
    Blob csvBlobContent = getCsvContent(curContentDocumentId);
    String csvStringContent = blobToString(csvBlobContent);
    return csvStringContent.replaceAll('(\r\n|\r)', '\n');
  }

  private static void initFieldTypeMap(
    SObjectType sObjType,
    List<String> fieldNames,
    Map<String, SChema.DisplayType> fieldToFieldTypeMap
  ) {
    Map<String, SObjectField> fieldMap = sobjFieldsMap.get(sObjType);
    if (fieldMap == null) {
      fieldMap = sObjType.getDescribe().fields.getMap();
      sobjFieldsMap.put(sObjType, fieldMap);
    }
    for (String field : fieldNames) {
      fieldToFieldTypeMap.put(field, getFieldType(fieldMap, field));
    }
  }

  private static void setSObjectField(
    SObject obj,
    String fieldName,
    Schema.DisplayType fieldType,
    String value,
    Boolean setNull
  ) {
    if (String.isBlank(value)) {
      if (setNull)
        obj.put(fieldName, null);
    } else {
      obj.put(fieldName, getConvertedFieldValue(fieldType, value));
    }
  }

  static Blob getCsvContent(String contentDocumentId) {
    ContentVersion csvFile = [
      SELECT VersionData
      FROM ContentVersion
      WHERE ContentDocumentId = :contentDocumentId AND IsLatest = TRUE
    ];
    System.debug('contentDocumentId is: ' + contentDocumentId);
    System.debug('csvFile is: ' + csvFile);
    return csvFile.VersionData;
  }

  static String blobToString(Blob input) {
    return input.toString();
  }

  /* Converting the CSV file input(BLOB format) to a string */
  static String blobToString(Blob input, String inCharset) {
    String hex = EncodingUtil.convertToHex(input);
    System.assertEquals(0, hex.length() & 1);
    final Integer bytesCount = hex.length() >> 1;
    String[] bytes = new List<String>(bytesCount);
    for (Integer i = 0; i < bytesCount; ++i)
      bytes[i] = hex.mid(i << 1, 2);
    return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
  }

  static Object getConvertedFieldValue(Schema.DisplayType fieldType, String fieldValue) {
    Object convertedFieldValue;
    switch on
      fieldType { //Setting Field value based on the field data type
      when BOOLEAN {
        convertedfieldValue = String.isEmpty(fieldValue) ? false : Boolean.valueOf(fieldValue);
      }
      when DOUBLE {
        convertedfieldValue = String.isEmpty(fieldValue) ? null : Decimal.valueOf(fieldValue);
      }
      when CURRENCY {
        convertedfieldValue = String.isEmpty(fieldValue) ? null : Decimal.valueOf(fieldValue);
      }
      when INTEGER {
        convertedfieldValue = String.isEmpty(fieldValue) ? null : Integer.valueOf(fieldValue);
      }
      when else {
        convertedfieldValue = fieldValue;
      }
    }
    return convertedFieldValue;
  }

  @TestVisible
  static Schema.DisplayType getFieldType(Map<String, SObjectField> fieldMap, String fieldApiName) {
    if (fieldMap.get(fieldApiName) == null) {
      throw new FlowCustomException(
        'Invalid Field Error: ' +
        fieldApiName +
        '. Please double check the API name of the field.'
      );
    }
    return fieldMap.get(fieldApiName).getDescribe().getType();
  }

  public class FlowCustomException extends Exception {
  }

  public class Request {
    @InvocableVariable(label='Object API Name' required=true)
    public string objectApiName;

    @InvocableVariable(label='Single CSV File ID')
    public string contentDocumentId;

    @InvocableVariable(label='List of CSV File IDs')
    public List<String> contentDocumentIdList;

    @InvocableVariable(label='Set Nulls')
    public Boolean setNullValues;
  }

  public class Response {
    @InvocableVariable(label='List(collection) of Records')
    public List<SObject> convertedCSVRows;
  }
}