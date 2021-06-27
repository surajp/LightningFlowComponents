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

  private Integer getPositionOfNextTextQualifier() {
    return this.row.indexOf(this.textQualifier, this.currentIndex + 1);
  }

  private Integer getPositionOfNextColDelimiter() {
    return this.row.indexOf(colDelimiter, this.currentIndex + 1);
  }

  private String nextToken(String token) {
    Integer qualifierIndex = this.row.indexOf(this.textQualifier, this.currentIndex + 1);
    Integer colDelimIndex = this.row.indexOf(this.colDelimiter, this.currentIndex + 1);
    System.debug('>>>000 qualifier ' + this.textQualifier);
    System.debug('>>>000 colindex ' + colDelimIndex);
    System.debug('>>>000 qualifierIndex ' + qualifierIndex);
    System.debug('>>>000 currentIndex ' + this.currentIndex);
    if (this.isLastChar()) {
      this.currentIndex++;
      return token;
    }
    if (colDelimIndex == -1) {
      token += this.row.substring(this.currentIndex + 1);
      this.currentIndex = this.rowLength;
      return token;
    }
    if (qualifierIndex > -1 && qualifierIndex < colDelimIndex) {
      token += this.row.substring(this.currentIndex + 1, qualifierIndex);
      if (preserveTextQualifier) {
        token += this.textQualifier;
      }
      this.currentIndex = qualifierIndex + this.qualifierLength - 1;
      qualifierIndex = this.row.indexOf(this.textQualifier, this.currentIndex + 1);
      token += this.row.substring(this.currentIndex + 1, qualifierIndex);
      this.currentIndex = qualifierIndex + this.qualifierLength - 1;
      if (preserveTextQualifier) {
        token += this.textQualifier;
      }
      return this.nextToken(token);
    }
    token += this.row.substring(this.currentIndex + 1, colDelimIndex);
    System.debug('>>>000 token ' + token);
    this.currentIndex = colDelimIndex + this.delimiterLength - 1;
    System.debug('>>>000 new current index ' + this.currentIndex);
    return token;
  }

  public String next() {
    return this.nextToken('');
  }
}
