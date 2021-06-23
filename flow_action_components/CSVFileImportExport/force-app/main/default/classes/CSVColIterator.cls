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
  private Integer currentIndex = 0;
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
    return currentIndex < row.length() || (this.isLastChar() && this.rowEndsWithDelimiter);
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
    return this.currentIndex == this.rowLength;
  }

  private Integer getPositionOfNextTextQualifier() {
    return this.row.indexOf(this.textQualifier, this.currentIndex + 1);
  }

  private Integer getPositionOfNextColDelimiter() {
    return this.row.indexOf(colDelimiter, currentIndex);
  }

  public String next() {
    String token = '';
    if (this.isLastChar()) {
      // indicates that the row ends with a delimiter (comma) and last column is blank
      this.currentIndex++;
    } else if (this.currentChar() == this.textQualifier) {
      Integer key = this.getPositionOfNextTextQualifier();
      token = this.row.substring(this.currentIndex + 1, key); //read column value
      this.currentIndex = key + 2;
    } else {
      Integer key = this.getPositionOfNextColDelimiter();
      if (key == -1) {
        //we are at the end of the row and there are no more column delimiters
        key = row.length();
      }
      token = row.substring(currentIndex, key); //read column value
      this.currentIndex = key + 1;
    }
    return token;
  }
}
