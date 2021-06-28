@isTest
public with sharing class ConvertCSVToRecordsTest {
  @TestSetup
  static void createData() {
    ContentVersion cv = new ContentVersion(
      Title = 'Demo Accounts CSV',
      VersionData = createCSVBlob(),
      PathOnClient = 'DemoAccounts.csv'
    );
    insert cv;
  }

  @isTest
  static void testconvertMethodExceptions() {
    ConvertCSVToRecords.Request[] flowInputs = createFlowInputsList();

    /* 1. FlowInput list size more than 1 exception
     */
    try {
      ConvertCSVToRecords.Request input = new ConvertCSVToRecords.Request();
      flowInputs.add(input);
      ConvertCSVToRecords.Response[] flowOutputs = ConvertCSVToRecords.convert(flowInputs);
    } catch (Exception e) {
      System.assert(e.getMessage().contains('This action is only supported in Screen flows.'));
    }
  }

  @isTest
  static void testconvertMethod() {
    ConvertCSVToRecords.Request[] flowInputs = createFlowInputsList();
    Test.startTest();
    ConvertCSVToRecords.Response[] flowOutputs = ConvertCSVToRecords.convert(flowInputs);
    Test.stopTest();
    System.assert(flowOutputs[0].convertedCSVRows.size() == 3);
  }

  @isTest
  static void testGetFieldTypeMethodException() {
    try {
      ConvertCSVToRecords.getFieldType(Schema.SObjectType.Account.fields.getMap(), 'TestField');
    } catch (Exception e) {
      System.assert(e.getMessage().contains('Invalid Field Error'));
    }
  }

  static Blob createCSVBlob() {
    String csvStringContent;
    Blob csvBlobContent;
    string[] fields = new List<String>{ 'AccountNumber', 'AnnualRevenue', 'NumberOfEmployees', 'Rating', 'Name' };

    String csvHeader = String.join(fields, ',') + '\n';
    csvStringContent = csvHeader;

    Account[] accRecords = new List<Account>{
      new Account(
        Name = 'CSV Acc1',
        AnnualRevenue = null,
        AccountNumber = '',
        NumberOfEmployees = null,
        Rating = 'Hot'
      ),
      new Account(
        Name = 'CSV Acc2',
        AnnualRevenue = 1000,
        AccountNumber = '911',
        NumberOfEmployees = 0,
        Rating = 'Warm'
      ),
      new Account(
        Name = 'CSV Acc3',
        AnnualRevenue = 911007,
        AccountNumber = '007',
        NumberOfEmployees = 10,
        Rating = 'Cold'
      )
    };

    for (Integer i = 0; i < accRecords.size(); i++) {
      Account a = accRecords[i];
      for (Integer j = 0; j < fields.size(); j++) {
        String field = fields[j];
        csvStringContent = csvStringContent + (a.get(field) == null ? '' : a.get(field));
        if (j < fields.size() - 1) {
          csvStringContent += +',';
        }
      }
      if (i < accRecords.size() - 1) {
        csvStringContent += '\n';
      }
    }
    return Blob.valueOf(csvStringContent);
  }

  static ConvertCSVToRecords.Request[] createFlowInputsList() {
    String contentDocumentId;
    ContentVersion cv = [SELECT ContentDocumentId, FileType FROM ContentVersion WHERE Title = 'Demo Accounts CSV'];
    ConvertCSVToRecords.Request[] flowInputs = new List<ConvertCSVToRecords.Request>{};
    ConvertCSVToRecords.Request input = new ConvertCSVToRecords.Request();
    input.objectApiName = 'Account';
    input.contentDocumentId = cv.ContentDocumentId;
    flowInputs.add(input);

    return flowInputs;
  }

  @isTest //performance test the iterator
  private static void it_should_create_sobject_records_from_csv() {
    String csv = 'Name,Description,Rating,Industry,Site';
    Integer NUM_OF_ROWS = 4000;
    //rows without text qualifier
    for (Integer i = 0; i < NUM_OF_ROWS / 2; i++) {
      csv += '\nAccount - ' + i + ',Sample Account - ' + i + ',Warm,Agriculture,My Account Site';
    }

    //rows with text qualifier
    for (Integer i = 2000; i < NUM_OF_ROWS; i++) {
      csv += '\n"Account , ' + i + '","Sample, Account - ' + i + '",Warm,Agriculture,My Account Site';
    }

    Long t1 = System.now().getTime();
    List<Account> accts = (List<Account>) ConvertCSVToRecords.getSObjectRecordsFromCsv(csv, Account.SObjectType, false);
    System.debug('>> time taken ' + (System.now().getTime() - t1));
    system.assertEquals(NUM_OF_ROWS, accts.size(), 'Not all csv rows were converted to accounts');
  }
}
