/************************************************************

*** @author Suraj Pillai
*** @date 06/2021
*** @description A custom iterator for iterating over a single row of comma-separated values. Handles text qualifiers if present
*** 
**/
public class CSVColIterator implements Iterator<String> {
  private String colDelimiter = ',';
  private String textQualifier = '"';
  private String row = '';
  private Integer rowLength = 0;
  private Integer delimiterLength = 1;
  private Integer qualifierLength = 1;
  private Integer currentIndex = -1;
  private Boolean rowEndsWithDelimiter = false; //Does the row end with a delimiter i.e. is the last column blank?
  private Boolean preserveTextQualifier = false; //Preserve text qualifiers in the output
  private static String textDelimiterReplacementString = '----';

  public CSVColIterator(String row) {
    this.row = row.replace('\\' + this.textQualifier, textDelimiterReplacementString);
    this.rowLength = row.length();
    this.checkIfRowEndsWithDelimiter();
  }

  private void checkIfRowEndsWithDelimiter() {
    this.rowEndsWithDelimiter = row.substring(row.length() - 1).equals(this.colDelimiter);
  }

  public Boolean hasNext() {
    return currentIndex < this.rowLength || (this.isLastChar() && this.rowEndsWithDelimiter);
  }

  public CSVColIterator setPreserveTextQualifier(Boolean preserveTextQualifier) {
    this.preserveTextQualifier = preserveTextQualifier;
    return this;
  }

  /****
   ** @description override the default column delimiter (comma)
   ** @param delimiter The delimiter that will replace comma
   ** @return CSVColIterator
   **/
  public CSVColIterator setColDelimiter(String delimiter) {
    this.colDelimiter = delimiter;
    this.checkIfRowEndsWithDelimiter();
    this.delimiterLength = delimiter.length();
    return this;
  }

  /****
   ** @description override the default text qualifier (double quotes).
   ** @param textQualifier The new text qualifier to use instead of double-quotes
   ** @return CSVColIterator
   **/
  public CSVColIterator setTextQualifier(String textQualifier) {
    this.textQualifier = textQualifier;
    this.qualifierLength = textQualifier.length();
    return this;
  }

  private String currentChar() {
    return this.row.substring(this.currentIndex, this.currentIndex + 1);
  }

  private Boolean isLastChar() {
    return this.currentIndex == this.rowLength - 1;
  }

  private Integer getPositionOfNextTextQualifierAfter(Integer startIndex) {
    return this.row.indexOf(this.textQualifier, startIndex + 1);
  }

  private Integer getPositionOfNextColDelimiterAfter(integer startIndex) {
    return this.row.indexOf(this.colDelimiter, startIndex + 1);
  }

  private Boolean currentColumnHasTextQualifier(Integer qualifierIndex, Integer colDelimIndex) {
    return qualifierIndex > -1 && qualifierIndex < colDelimIndex;
  }

  private String getTextUntil(Integer endIndex) {
    return this.row.substring(this.currentIndex + 1, endIndex);
  }

  private String nextToken(String token) {
    Integer qualifierIndex = this.getPositionOfNextTextQualifierAfter(this.currentIndex);
    Integer colDelimIndex = this.getPositionOfNextColDelimiterAfter(this.currentIndex);

    /*
    System.debug('*** delimIndex ' + colDelimIndex);
    System.debug('*** qualifierIndex ' + qualifierIndex);
    System.debug('*** currentIndex ' + this.currentIndex);
    */
    // If we are at the end of the row, increment the cursor position by 1 and return the token
    if (this.isLastChar()) {
      this.currentIndex++;
      return token;
    }

    /* If there are no more column delimiters, return the entire rest of the string and set the cursor
     position to the end of the string */
    if (colDelimIndex == -1) {
      token += this.row.substring(this.currentIndex + 1);
      this.currentIndex = this.rowLength;
      return token;
    }

    // If we come across a text qualifier, find the closing text qualifier and then find the next column delimiter
    if (this.currentColumnHasTextQualifier(qualifierIndex, colDelimIndex)) {
      qualifierIndex = this.getPositionOfNextTextQualifierAfter(qualifierIndex); //find closing text qualifier position
      token += this.getTextUntil(qualifierIndex);
      this.currentIndex = qualifierIndex + this.qualifierLength - 1;
      if (this.preserveTextQualifier) {
        token += this.textQualifier;
      } else {
        token = token.replaceAll(this.textQualifier, '');
      }
      return this.nextToken(token);
    }

    token += this.getTextUntil(colDelimIndex);
    this.currentIndex = colDelimIndex + this.delimiterLength - 1;
    return token;
  }

  public String next() {
    String token = this.nextToken('');
    //System.debug('*** token ' + token);
    return token.replace(textDelimiterReplacementString, this.textQualifier);
  }
}
