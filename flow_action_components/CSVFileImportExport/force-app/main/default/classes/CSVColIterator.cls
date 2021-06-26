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
  private Integer currentIndex = -1;
  private Boolean rowEndsWithDelimiter = false; //Does the row end with a delimiter i.e. is the last column blank?

  public CSVColIterator(String row) {
    this.row = row;
    this.rowLength = row.length();
    this.checkIfRowEndsWithDelimiter();
  }

  private void checkIfRowEndsWithDelimiter() {
    this.rowEndsWithDelimiter = row.substring(row.length() - 1).equals(this.colDelimiter);
  }

  public Boolean hasNext() {
    System.debug('>> currIndex ' + this.currentIndex);
    return currentIndex < this.rowLength || (this.isLastChar() && this.rowEndsWithDelimiter);
  }

  /****
   ** @description override the default column delimiter (comma)
   ** @param delimiter The delimiter that will replace comma
   ** @return CSVColIterator
   **/
  public CSVColIterator setColDelimiter(String delimiter) {
    this.colDelimiter = delimiter;
    this.checkIfRowEndsWithDelimiter();
    return this;
  }

  /****
   ** @description override the default text qualifier (double quotes).
   ** @param textQualifier The new text qualifier to use instead of double-quotes
   ** @return CSVColIterator
   **/
  public CSVColIterator setTextQualifier(String textQualifier) {
    this.textQualifier = textQualifier;
    return this;
  }

  private String currentChar() {
    return this.row.substring(this.currentIndex, this.currentIndex + 1);
  }

  private Boolean isLastChar() {
    return this.currentIndex == this.rowLength - 1;
  }

  private Integer getPositionOfNextTextQualifier() {
    return this.row.indexOf(this.textQualifier, this.currentIndex + 1);
  }

  private Integer getPositionOfNextColDelimiter() {
    return this.row.indexOf(colDelimiter, currentIndex);
  }

  private String nextToken(String token) {
    Integer qualifierIndex = this.row.indexOf(this.textQualifier, this.currentIndex + 1);
    Integer colDelimIndex = this.row.indexOf(this.colDelimiter, this.currentIndex + 1);
    if (this.currentIndex == this.rowLength - 1) {
      this.currentIndex++;
      return token;
    } else if (colDelimIndex == -1) {
      token += this.row.substring(this.currentIndex + 1);
      this.currentIndex = this.rowLength;
      return token;
    }
    if (qualifierIndex > -1 && qualifierIndex < colDelimIndex) {
      token += this.row.substring(this.currentIndex + 1, qualifierIndex);
      this.currentIndex = qualifierIndex;
      qualifierIndex = this.row.indexOf(this.textQualifier, this.currentIndex + 1);
      token += this.row.substring(this.currentIndex + 1, qualifierIndex);
      this.currentIndex = qualifierIndex;
      return this.nextToken(token);
    }
    token += this.row.substring(this.currentIndex + 1, colDelimIndex);
    this.currentIndex = colDelimIndex;
    return token;
  }

  public String next() {
    String token = '';
    if (this.isLastChar()) {
      // indicates that the row ends with a delimiter (comma) and last column is blank
      this.currentIndex++;
    } else {
      token = this.nextToken('');
    }
    return token;
  }
}
